-- Run only in an owned private profile after the P07 acceptance definitions.
global ARResults=#(),ARRecord,ARBasic,ARLine,ARAnalyzer
fn ARRecord key value = (
 append ARResults #(key,value)
 CSPWriteText (MCPFixtureDir+"arrangement-results.json") (CSPObject ARResults)
)
fn ARBasic = (
 P07Case="Arrangement research";P07New count:10000
 local r=P07Root,a=P07Layer,s=P07Source
 local other=box name:"AR_Flower" pos:[1200,100,0]
 a.sources=#(s,other);a.sourceWeights=#(1.0,0.25);a.sourceColors=#(red,blue)
 local random=(r.evaluateGroups())[1],n1=0
 for row in random where row[2]==1 do n1+=1
 ARRecord "random_weight_1_to_quarter" #(random.count,n1,random.count-n1)
 a.sourceWeights=#(1.0,1.0);a.diversityMode=2;a.diversitySize=180
 local clusters=(r.evaluateGroups())[1],same=0
 for i=1 to random.count where random[i][1].row4==clusters[i][1].row4 do same+=1
 ARRecord "random_to_clusters_same_positions" #(same,clusters.count)
 local old=cyrusEditFingerprint clusters "ar",builds=(a.procStatistics())[3]
 r.evaluateGroups()
 ARRecord "warm_cluster_builds" #(builds,(a.procStatistics())[3])
 a.setSourceIDColor #{1} yellow
 ARRecord "identification_color_preserves_output" ((cyrusEditFingerprint (r.evaluateGroups())[1] "ar")==old)
 a.diversitySeed+=1
 local changed=(r.evaluateGroups())[1],assignments=0,positions=0
 for i=1 to changed.count do (if changed[i][2]!=clusters[i][2] do assignments+=1;if changed[i][1].row4==clusters[i][1].row4 do positions+=1)
 ARRecord "cluster_seed_changes" #(assignments,positions)
 a.sourceWeights=#(1.0,0.0)
 local disabled=(r.evaluateGroups())[1]
 ARRecord "zero_weight_cluster" #(disabled.count,(for row in disabled where row[2]==2 collect row).count)
)
fn ARLine = (
 P07New count:10000
 local r=P07Root,a=P07Layer,s=P07Source,other=box name:"AR_Shrub" pos:[1200,100,0]
 a.sources=#(s,other);a.sourceWeights=#(1.0,1.0)
 local path=rectangle name:"AR_Guide" width:400 length:400
 a.diversityMode=3;a.patternPaths=#(path);a.patternLines=#(path,path)
 a.patternWidths=#(50.0,100.0);a.strokeSides=#(1,1);a.strokeModes=#(2,2)
 a.strokeSourceRows=#(1,2);a.strokeSourceNodes=#(s,other);a.strokeMin=#(1.0,1.0);a.strokeMax=#(1.0,1.0)
 local rows=(r.evaluateGroups())[1],wrong=0,counts=#(0,0)
 for row in rows do (
  local p=row[1].row4,dx=amax 0 (abs p.x-200),dy=amax 0 (abs p.y-200),d=sqrt(dx*dx+dy*dy)
  counts[row[2]]+=1
  if d<=0 or d>150.001 or (row[2]==1 and d>50.001) or (row[2]==2 and d<49.999) do wrong+=1
 )
 ARRecord "consecutive_bands" #(rows.count,counts,wrong)
 local fp=cyrusEditFingerprint rows "ar"
 path.pos.z=300
 ARRecord "line_z_offset_preserves_output" ((cyrusEditFingerprint (r.evaluateGroups())[1] "ar")==fp)
 path.pos.z=0
 local second=copy path
 a.patternLines=#(path,second);a.patternWidths=#(100.0,100.0)
 rows=(r.evaluateGroups())[1]
 ARRecord "overlap_first_guide_wins" #(rows.count,(for row in rows where row[2]==2 collect row).count)
 a.strokeSourceNodes=#(other,s)
 rows=(r.evaluateGroups())[1]
 ARRecord "overlap_swapped_source_first_wins" #(rows.count,(for row in rows where row[2]==1 collect row).count)
 a.patternLines=#();a.patternWidths=#();a.strokeSides=#()
 ARRecord "no_bands_count" (r.evaluateGroups())[1].count
)
fn ARAnalyzer = (
 P07New count:3000
 local r=P07Root,a=P07Layer,s=P07Source,node=CyrusSurfaceAnalyzer name:"AR_Analyzer",an=node.baseObject
 an.surface=P07Surface;an.resolution=48;an.pointRadius=70;an.fitRadius=40;an.relaxIterations=0;an.updateMode=1
 local street=splineShape name:"AR_Street"
 addNewSpline street;addKnot street 1 #corner #line [-700,-510,0];addKnot street 1 #corner #line [700,-510,0];updateShape street
 an.streetLine=street;an.streetDistance=100;an.streetAngle=30
 an.runAnalysis()
 ARRecord "analyzer_publication" #(an.boundaryVertices.count,an.pathVertices.count,an.samplePoints.count,an.streetVertices.count,an.resultText)
 a.diversityMode=4;a.analyzerNode=node;a.patternLines=#(node);a.patternWidths=#(80.0);a.strokeSides=#(2);a.strokeModes=#(2)
 a.strokeSourceRows=#(1);a.strokeSourceNodes=#(s);a.strokeMin=#(1.0);a.strokeMax=#(1.0)
 for side in #(2,3,4,5,6,7) do (
  a.strokeSides=#(side);a.patternWidths=#(80.0)
  local rows=(r.evaluateGroups())[1]
  ARRecord ("analyzer_channel_"+(side as string)) #(rows.count,a.previewError)
 )
 local edge=(r.evaluateGroups())[1],fp=cyrusEditFingerprint edge "ar",runs=an.getAnalysisRuns(),builds=(a.procStatistics())[3]
 r.evaluateGroups()
 ARRecord "analyzer_warm_reuse" #(runs,an.getAnalysisRuns(),builds,(a.procStatistics())[3])
 a.amount=6000
 ARRecord "edge_count_vs_amount" #(edge.count,(r.evaluateGroups())[1].count)
 a.amount=0
 ARRecord "edge_count_at_zero_amount" (r.evaluateGroups())[1].count
 a.amount=3000;P07Surface.width=1200
 r.evaluateGroups()
 ARRecord "manual_analyzer_scatter_update_does_not_analyze" #(runs,an.getAnalysisRuns())
 an.runAnalysis()
 ARRecord "explicit_analyzer_reanalysis" #(an.getAnalysisRuns(),(r.evaluateGroups())[1].count)
 a.strokeSides=#(2);a.patternWidths=#(80.0)
 local border=(r.evaluateGroups())[1]
 P07Surface.pos.z=10
 ARRecord "stale_analyzer_receiver_moved_z" #(border.count,(r.evaluateGroups())[1].count)
)

global ARExtra
fn ARExtra = (
 P07New count:100000
 local r=P07Root,a=P07Layer,s=P07Source,other=box name:"AR_PerfOther" pos:[1200,100,0]
 a.sources=#(s,other);a.sourceWeights=#(1.0,1.0);a.sourceColors=#(red,blue);a.diversitySize=180
 local path=rectangle name:"AR_PerfGuide" width:400 length:400
 a.patternLines=#(path);a.patternWidths=#(100.0);a.strokeSides=#(1);a.strokeModes=#(2)
 a.strokeSourceRows=#(1);a.strokeSourceNodes=#(s);a.strokeMin=#(1.0);a.strokeMax=#(1.0)
 for mode=1 to 3 do (
  a.diversityMode=mode
  local timings=#(),warm=#(),rows,clock=dotNetObject "System.Diagnostics.Stopwatch"
  for k=1 to 3 do (
   a.randomSeed+=1;clock.Restart();rows=(r.evaluateGroups())[1];clock.Stop();append timings clock.Elapsed.TotalMilliseconds
   clock.Restart();r.evaluateGroups();clock.Stop();append warm clock.Elapsed.TotalMilliseconds
  )
  ARRecord ("100k_mode_"+(mode as string)) #(rows.count,timings,warm)
 )
 -- A band retains a scene-node binding but currently lists node.name, not its Scatter alias.
 a.setSourceLabel 1 "Friendly grass"
 ARRecord "model_alias_and_scene_name" #(a.sourceLabel 1,s.name)
 -- Compare candidate-budget and bounded accepted-target policies on one narrow band.
 a.amount=1000;a.procPopulation=1
 local budget=(r.evaluateGroups())[1].count
 a.procPopulation=2;a.procAttemptFactor=8;a.procRounds=4
 ARRecord "band_candidate_budget_vs_accepted_target" #(budget,(r.evaluateGroups())[1].count)
 P07New count:1000
 r=P07Root;a=P07Layer;s=P07Source
 local node=CyrusSurfaceAnalyzer name:"AR_CurvedAnalyzer",an=node.baseObject,ball=sphere radius:100 segs:16
 an.surface=ball;an.resolution=48;an.relaxIterations=0;an.updateMode=1
 local error=""
 try(an.runAnalysis())catch(error=getCurrentException())
 ARRecord "sphere_analyzer" #(error,an.resultText,an.boundaryVertices.count)
)
