-- The Python body uses the same-process Qt/WinForms event loops only.
global ECMzpRun,ECMzpPython=(getFilenamePath(getSourceFileName()))+"mzp_adapter.py"
fn ECMzpRun scenario = (
    if scenario!="EC-I" do throw "Unexpected owned installer scenario"
    python.ExecuteFile ECMzpPython
)
