jc2mp-model-viewer
==================

A simple model viewer for JC2-MP that lets you collaboratively view models. Simply load up the script and use /modelviewer to join/exit the current model viewer session.

Initially, your camera will be 'unlocked' and free to move around the object (if there is one). To select an object, press your Reload button to lock the camera in place so that you can select a model.

The model and collision path for the selected model will be shown at the bottom of the window. Simply use it as-is within your script. However, be aware that some models do not necessarily have matching collisions; they either may not exist, or are misnamed. In the latter case, you may have to manually find them (by using Gibbed's Archive Viewer and related tools)

Multiple users can use the model viewer at once; they will all view the same model. If one user changes the model, it will be changed for all users.