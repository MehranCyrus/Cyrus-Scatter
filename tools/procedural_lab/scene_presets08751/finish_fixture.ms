-- Pymxs scene construction may leave its owned fixture hold open. Finish that
-- construction before testing the real rollout-style save command.
if theHold.Holding() do theHold.Accept "Owned scene-preset fixture construction"
