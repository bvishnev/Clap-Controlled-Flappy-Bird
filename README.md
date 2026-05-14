# Clap Controlled Flappy Bird
This project implements a clap-activated Flappy-Bird-inspired game. The game runs on a Spartan 7 FPGA and is displayed using the HDMI output on the [Urbana Board](https://www.realdigital.org/hardware/urbana). The key feature of the game is that you must make a loud noise, such as a clap or snap, near the board's microphone to trigger the bird to jump. The goal of the game is to jump through green pipes which appear starting at the right of the screen and move left. There are also clouds which move from the right to the left of the screen to create added realism. The pipes and clouds both use pseudo-random number generators to determine some of their parameters including but not limited to the height for the pipes and the size of the clouds. The score is displayed on the screen in decimal format.

The design implements the flappy bird game entirely in hardware on the Urbana board, utilizing the onboard microphone chip for sound input. The input is used to control the bird on the screen, while other hardware modules generate positions for other objects. An FSM controls the state of the game, and the score is tracked using the positions of the pipes. All of this information is combined to generate a VGA signal that describes the graphics on the screen, which is then converted to HDMI by the RealDigital IP for display on a monitor.

For more information, see the detailed report included in this repository.


