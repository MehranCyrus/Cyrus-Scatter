CYRebind()
clearSelection();max create mode
viewport.setLayout #layout_1;viewport.setCamera CYCam;viewport.setRenderLevel #smoothhighlights
for spec in #(#("nav-points",1,1),#("nav-box",2,1),#("nav-sphere",2,2),#("nav-pyramid",2,3),#("nav-mesh",3,1),#("nav-centres",4,1)) do CYNavigate spec[1] spec[2] spec[3] 1000
CYR.viewportInstances=10000;CYR.setGroupDisplay 1;CYR.refreshDisplay();CYR.updateMode=1
CYLog "material-fields" #(#("physical",getPropNames CYReceivers[1].material),#("camera",CYCam.pos as string))
