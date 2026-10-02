HVPMode "retained"
CSPWriteText (HVPDir+"pilot-stats.json") (CSPJson (HVPStats()))
HVPCapture "pilot-retained"
HVPMode "gw"
HVPCapture "pilot-gw"
HVPMode "off"
HVPCapture "pilot-off"
HVPMode "retained"
