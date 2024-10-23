include <handyfunctions.scad>

module stealth_lock(slop=0) {

    /* Measured reality */
    measured_cylinder_diameter = 6.03;
    measured_total_height = 10.27;
    measured_block_length = 19;
    measured_block_width = 2.65;
    
    measured_bolt_cylinder_diameter = 5.6;
    measured_bolt_total_height = 8.84;
    measured_bolt_small_length = 3.45;
    measured_bolt_big_length = 4.55;

    /* Compute the dimension of the lock space, including the "slop" as a margin. */
    cylinder_diameter = measured_cylinder_diameter + 2 * slop;
    block_height = measured_total_height - measured_cylinder_diameter / 2 + slop; 
    block_length = measured_block_length;
    block_width = measured_block_width + 2 * slop;

    bolt_height = measured_bolt_total_height - measured_bolt_cylinder_diameter / 2 + slop;
    bolt_small_length = measured_bolt_small_length + slop;
    bolt_big_length = measured_bolt_big_length + slop;
    bolt_rotation = 55;
    bolt_width = 2;

    union() {
        rx(90) cylinder(d=cylinder_diameter, h=block_length);
        dx(-block_width/2) dy(-block_length) dz(-block_height) {
            cube([block_width, block_length, block_height]);
        }
        dx(-bolt_width/2) ry(90) rx(90) rotate_extrude(angle=-bolt_rotation) {
            polygon(points=[[0,0],[bolt_height,0],[bolt_height,bolt_small_length],[0,bolt_big_length]], paths=[[0,1,2,3]]);
        }
    }
}
