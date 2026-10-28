(
    if not matchPattern GardenRun pattern:"*/build/drag08756-20261028-01/host-*/" do throw "Owned profile required"
    if not saveMaxFile (GardenRun+"manual-trial.max") quiet:true do throw "Could not preserve the disposable trial"
)
