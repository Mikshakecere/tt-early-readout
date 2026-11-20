# SPDX-License-Identifier: Apache-2.0
#
# SPDX-FileCopyrightText: © 2025 Tenstorrent AI ULC

from typing import Optional

from domain.base_request import BaseRequest
from pydantic import Field, model_validator


class VideoGenerateRequest(BaseRequest):
    # Required fields
    prompt: str

    # Optional fields
    negative_prompt: Optional[str] = None
    num_inference_steps: Optional[int] = Field(default=20, ge=12, le=50)
    seed: Optional[int] = None
    # Early denoising readout (local patch): stop after this many steps and
    # decode the x0 estimate. None falls back to WAN_STOP_AFTER_STEP on the
    # container, or the full schedule if that is unset.
    stop_after_step: Optional[int] = Field(default=None, ge=1, le=50)

    @model_validator(mode="after")
    def _check_stop_after_step(self):
        steps = self.num_inference_steps if self.num_inference_steps is not None else 20
        if self.stop_after_step is not None and self.stop_after_step > steps:
            raise ValueError(
                f"stop_after_step ({self.stop_after_step}) must be <= num_inference_steps ({steps})"
            )
        return self
