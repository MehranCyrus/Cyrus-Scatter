"""MCP-facing JSON schema; Max independently validates the same contract."""
from typing import Annotated, Literal
from pydantic import BaseModel, ConfigDict, Field

Identifier=Annotated[str,Field(pattern=r"^[A-Za-z0-9_-]{1,96}$")]
Label=Annotated[str,Field(min_length=1,max_length=80,pattern=r"^[^\x00-\x1f]*$")]
ScaleValue=Annotated[float,Field(ge=.01,le=10,allow_inf_nan=False)]
YawValue=Annotated[float,Field(ge=-360,le=360,allow_inf_nan=False)]


class Closed(BaseModel):
    model_config=ConfigDict(extra="forbid",strict=True)


class Source(Closed):
    source_id: Identifier
    weight: Annotated[float,Field(ge=0,le=1,allow_inf_nan=False)]


class Layer(Closed):
    name: Label
    region_id: Identifier
    count: Annotated[int,Field(ge=0,le=2000)]
    seed: Annotated[int,Field(ge=0,le=2147483646)]
    sources: Annotated[list[Source],Field(min_length=1,max_length=3)]
    scale: Annotated[list[ScaleValue],Field(min_length=2,max_length=2)]
    yaw_degrees: Annotated[list[YawValue],Field(min_length=2,max_length=2)]
    underfill: Literal["allow","reject"]


class DesignPlan(Closed):
    schema_version: Literal["1.0"]
    context_id: Identifier
    name: Label
    layers: Annotated[list[Layer],Field(min_length=1,max_length=3)]
    controller_id: Identifier | None = None
    generation_id: Identifier | None = None
    clearance_m: Annotated[float,Field(ge=0,le=100,allow_inf_nan=False)] = 0


class ResponseEnvelope(BaseModel):
    model_config=ConfigDict(extra="allow")
    ok: bool
