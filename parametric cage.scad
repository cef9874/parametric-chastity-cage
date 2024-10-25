////////////////////////////////////
//
// Parametric chastity cage, modified from this one: https://www.thingiverse.com/thing:2764421/
// Version 3, published August 2018

// V4 update: February 2019
//    - Added option to bend the base ring, for comfort
//    - Updated variables for Thingiverse Customizer

// V5 update: June 2019
//    - Rewrote as many functions as possible

// V6 update: January 2021
//    - Another major overhaul

//////////////////////////////////////

// Use abbreviations for translate() and rotate() operations
use <handyfunctions.scad>

// Use separate module for stealth lock shape
use <stealth_lock.scad>

// Use separate module for torus functions
use <torus.scad>

// Use separate module for computing points along the cage path
use <vec3math.scad>

// Render cage and ring separately
separateParts = 1; // [0: Together, 1: Separate]

// Is the cage spiked or not ? 
spiked = false;
base_spiked = false;

// Cage diameter
cage_diameter=35; // [30:40]

// Length of cage from base ring to cage tip
penis_length=90; // [30:200]

// Base ring diameter
base_ring_diameter=45; // [30:55]

// Thickness of base ring 
base_ring_thickness=6; // [6:10]

// Add a "wave" to the base ring (contours to the body a little better)
wavyBase = 1; // [0: Flat, 1: Wavy]

// If the base ring has a wave, set the angle of the wave
waveAngle = 12; // [0:45]

// Gap between the bottom of the cage and the base ring
gap=10; // [10:20]

// Thickness of the rings of the cage
cage_bar_thickness=4; // [4:8]

// Number of vertical bars on the cage
cage_bar_count=8;

// Width of the slit at the front opening
slit_width=12; // [0:40]

// Tilt angle of the cage at the base ring
tilt=15; // [0:30]

// If your lock fits too tightly in the casing, add some space around it here
lock_margin = 0.2; // [0:0.01:1]

// If the two parts slide too stiffly, add some space here
part_margin = 0.2; // [0:0.01:1]

// X-axis coordinate of the bend point (the center of the arc the cage bends around)
bend_point_x=50; // [0:0.1:200]

// Z-axis coordinate of the bend point (the center of the arc the cage bends around)
bend_point_z=15; // [0:0.1:200]

/* [Hidden] */

// Glans cage height (minimum is cage radius)
glans_cage_height=cage_diameter/2; // [15:50]

// Variables affecting the lock case
lock_case_upper_radius = 9;
lock_case_lower_radius = 4;
base_lock_bridge_width = 11;
mount_width=5;
mount_height=18;
mount_length=24;

// Radius of rounded edges
rounding=.99;

// Square function for math
function sq(x) = pow(x, 2);


////////////////////////////////////
//
// Useful values calculated from parameters above
//

// Thickness of base ring of cage
cage_ring_thickness = 1.2*cage_bar_thickness;

// step: angle between cage bars
step = 360/cage_bar_count;

// R1: Inner radius of shaft of cage
// R2: Inner radius of base ring
R1 = cage_diameter/2;
R2 = base_ring_diameter/2;

// r1: cage bar radius
// r2: base ring radius
// r3: cage ring radius
r1 = cage_bar_thickness/2;
r2 = base_ring_thickness/2;
r3 = cage_ring_thickness/2;

// Length of cage
cage_length = max(penis_length-gap, glans_cage_height+(R1+r1)*sin(tilt));

// Vertical placement of lock hole
lock_vertical = mount_height/2+1.5;
// Horizontal placement of lock hole
lock_lateral = 4.5;

// P: bend point (assumed to be on the XZ plane)
// dP: distance from origin to bend point
P = [bend_point_x, 0, bend_point_z];
dP = norm(P);

// psi: angle from origin to bend point (in degrees)
psi = atan(P.z/P.x);

// dQ: length of straight cage segment
dQ = min(dP*cos(90-tilt-psi), cage_length-glans_cage_height);

// Q: upper endpoint of straight segment of cage
Q = [dQ*sin(tilt), 0, dQ*cos(tilt)];

// Phi: arc length of curved segment of cage (in degrees)
curve_radius = norm(P-Q);
Phi = (cage_length - dQ - glans_cage_height)/curve_radius * 180/PI;

// R: endpoint of curved segment of cage
R = ry(Q-P, Phi) + P;

//slit_width = (R1+r1)*cos(step);

////////////////////////////////////
//
// Finally, here's where the modules begin
//
$fn=32;
make();

include <make.scad>;