"""MCP-facing JSON schema; Max independently validates the same contract."""
from typing import Annotated, Literal
from pydantic import BaseModel, ConfigDict, Field, create_model

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


def settings_model(name, registry):
    entries={}
    for key,(kind,default,bounds,_) in registry.items():
        if kind=="bool":annotation=bool
        elif kind=="enum":annotation=Literal.__getitem__(tuple(bounds))
        else:
            scalar=Annotated[int if kind=="int" else float,Field(ge=bounds[0],le=bounds[1],**({} if kind=="int" else {"allow_inf_nan":False}))]
            annotation=Annotated[list[scalar],Field(min_length=2,max_length=2)] if kind=="range" else scalar
        entries[key]=(annotation,default)
    return create_model(name,__base__=Closed,**entries)


from .settings import LAYER_SETTINGS, SOURCE_SETTINGS, DISPLAY_SETTINGS
LayerSettings=settings_model("LayerSettings",LAYER_SETTINGS)
SourceSettings=settings_model("SourceSettings",SOURCE_SETTINGS)
DisplaySettings=settings_model("DisplaySettings",DISPLAY_SETTINGS)


class SourceV2(Source):
    settings: SourceSettings = Field(default_factory=SourceSettings)


class LayerV2(Layer):
    sources: Annotated[list[SourceV2],Field(min_length=1,max_length=3)]
    settings: LayerSettings = Field(default_factory=LayerSettings)
    exclude_region_ids: Annotated[list[Identifier],Field(max_length=6)] = Field(default_factory=list)


class PairRule(Closed):
    a: Annotated[int,Field(ge=0,le=2)]
    b: Annotated[int,Field(ge=0,le=2)]
    gap_m: Annotated[float,Field(ge=0,le=100,allow_inf_nan=False)]
    footprints: bool
    planar: bool


class DesignPlanV2(DesignPlan):
    schema_version: Literal["2.0"]
    layers: Annotated[list[LayerV2],Field(min_length=1,max_length=3)]
    display: DisplaySettings = Field(default_factory=DisplaySettings)
    pair_rules: Annotated[list[PairRule],Field(max_length=3)] = Field(default_factory=list)


class ResponseEnvelope(BaseModel):
    model_config=ConfigDict(extra="allow")
    ok: bool
