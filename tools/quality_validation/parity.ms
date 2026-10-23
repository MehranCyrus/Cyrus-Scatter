fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
QSetup()
case QScenarioID of (
 "R5-M01": (local old=QFingerprint();QCalculate();QRequire (QFingerprint()==old) "Repeated ordered publication differs")
 "R5-M02": (
    QLayer.setSourceRadius #{1} 12;QLayer.setSourceClearance #{1} #clearanceCopies 2;QCalculate()
    local old=QFingerprint();QCalculate();QRequire (QFingerprint()==old) "Clearance repeatability differs"
    local rows=QRows();for i=1 to rows.count do for j=i+1 to rows.count do QRequire (distance rows[i][1].row4 rows[j][1].row4>=23.999) "Independent pair-distance oracle failed"
 )
 "R5-M03": (local old=QFingerprint(),epoch=QRoot.procEpoch;QLayer.amount=500;QMount();QRequire (QFingerprint()==old and QRoot.procEpoch==epoch) "Refactored view consumed pending settings")
 "R5-M04": (
    local old=QFingerprint(),epoch=QRoot.procEpoch,error="";QLayer.gridColumnWU=0;QLayer.placementMode=2
    try(QCalculate())catch(error=getCurrentException())
    QRequire (error!="" and QFingerprint()==old and QRoot.procEpoch==epoch) "Invalid grid changed complete publication"
 )
 "R5-M05": throw "Template byte parity is executed by the offline structural-extraction driver, not Max"
 "R5-M06": (
    local old=QFingerprint(),epoch=QRoot.procEpoch,builds=(QLayer.procStatistics())[3]
    for i=1 to 100 do QCalculate()
    QRequire (QFingerprint()==old and QRoot.procEpoch==epoch and (QLayer.procStatistics())[3]==builds) "Warm evaluation stopped reusing publication"
 )
 default: throw ("Unknown parity scenario: "+QScenarioID)
)
QAssert true (QScenarioID+"-01") "Parity/reuse and independent oracle checks completed"
