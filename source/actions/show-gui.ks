set _EXECUTING_GUI_BOOTLOADER to true.

set gui to gui(240).
set isDone to false.
set isProcessing to false.

// helper functions
function execute_action {
  parameter action.

  if addons:rt:hasconnection(ship) {
    copypath("0:/actions/" + action + ".ks", "").
    runpath(action).

    set isProcessing to false.
    deletepath("1:/" + action + ".ks").
  }
}

// actual GUI setup and operation
function build_gui_for_state {
  // clearguis().
  gui:clear().

  local didAddAction is false.

  local label is gui:addlabel("Choose Action").
  set label:style:align to "center".
  set label:style:hstretch to true.

  // if we're on the ground, set up a takeoff button
  if alt:radar < 30 {
    local takeoffBtn to gui:addbutton("Takeoff").

    set takeoffBtn:onclick to {
      set isProcessing to true.
      notify("Going to space...").
      execute_action("takeoff").
    }.

    set didAddAction to true.
  }

  // if there is a node available for execution set up a node execution button
  if hasnode {
    local execNodeBtn to gui:addbutton("Execute Node").

    set execNodeBtn:onclick to {
      set isProcessing to true.
      notify("Executing next node...").
      execute_action("execute-node").
    }.

    set didAddAction to true.
  }

  // if we haven't added any available actions then add a note indicating we'll
  // try again later
  if not didAddAction {
    local noActionLabel is gui:addlabel("No available actions.").
    set noActionLabel:style:align to "center".
    set noActionLabel:style:hstretch to true.
  }

  // set up a done button, to dismiss the gui
  gui:addspacing(16).
  local doneBtn to gui:addbutton("Done").
  set doneBtn:onclick to {
    set isDone to true.
    set isProcessing to true.
    gui:hide().
  }.

  gui:show().
}

// refresh the UI every 3 seconds
set t0 to time:seconds.

when not isDone and time:seconds >= t0 + 3 then {
  build_gui_for_state().
  set t0 to time:seconds.
  preserve.
}.

until isDone {
  wait until isProcessing.
}.
