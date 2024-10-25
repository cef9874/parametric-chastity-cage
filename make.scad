module make() {
  cage();
  make_base();
}

module make_base() {
  baseOrigin = separateParts ? [-base_ring_diameter-cage_diameter, 0, gap] : [0, 0, 0];
  translate(baseOrigin) {
    base_ring();
    lock_dovetail_outer();
  }
}

// Generate a cylinder with rounded edges
module rounded_cylinder(r,h,n, center=false) {
  zshift = center ? -h/2 : 0;
  dz(zshift) rotate_extrude(convexity=1) {
    offset(r=n) offset(delta=-n) square([r,h]);
    square([n,h]);
  }
}

// Generate a cube with rounded edges
module rounded_cube(size, radius, center=false) {
  offset = center ? [0, 0, 0] : [radius, radius, radius];
	translate(offset) minkowski() {
		cube(size = [
			size[0] - (radius * 2),
			size[1] - (radius * 2),
			size[2] - (radius * 2)
		], center=center);
		sphere(r = radius);
	}
}

module cage() {
  cage_bar_segments(); // The bars
  glans_cap(); // The cap
  torus(R1+r1, r3, spiked=spiked);  // Cage base ring
  cage_lock(); // The part where the lock goes
}

module cage_bar_segments() {
  for (theta = [step/2:step:360-step/2]) {
    // Straight segment begins at a point along the base ring, and ends at a point a distance R1 from point Q
    straightSegStart = rz([R1+r1, 0, 0], theta);
    straightSegEnd = Q + ry(straightSegStart, tilt);
    curveSegEnd = ry(straightSegEnd-P, Phi)+P;
    
    // make a cylinder between straightSegStart and straightSegEnd
    segAngle = 90-atan2(straightSegEnd.z - straightSegStart.z, straightSegEnd.x - straightSegStart.x);
    segLength = norm(straightSegEnd - straightSegStart);
    translate(straightSegStart) ry(segAngle) cylinder(r=r1, h=segLength);
    
    // Make a torus between straightSegEnd and curveSegEnd, if necessary
    if (Phi>0) {
      // First, find the angle between the ends of the curve
      vec1 = [straightSegEnd.x, 0, straightSegEnd.z]-P;
      vec2 = [curveSegEnd.x, 0, curveSegEnd.z]-P;
      curveAngle = acos(dot(vec1, vec2)/(norm(vec1)*norm(vec2)));
      curveRad = norm(vec1);
      translate(straightSegEnd) ry(-180+tilt) dx(-curveRad) rx(90) torus(curveRad, r1, -curveAngle, rounded=true);
    }
  }
}

module glans_cap() {
  // First, ensure the slit width is within the bounds of the cage geometry
  real_slit_width = max(min(slit_width, cage_diameter), 0.1);
  translate(R) ry(Phi+tilt) {
    // Ring around base of glans cap
    torus(R1+r1, r1, spiked=spiked);
    // Calculate the start and end points of the bars that create the front slit
    slitRadius = (R1+r1)*cos(asin(real_slit_width/2/(R1+r1)));
    slitStart = [slitRadius, -real_slit_width/2, 0];
    slitEnd = mx(slitStart);
    
    // Draw slit bars
    dy(-real_slit_width/2) rx(90) torus(slitRadius, r1, 180, spiked=spiked);
    dy(real_slit_width/2) rx(90) torus(slitRadius, r1, 180, spiked=spiked);
    
    // Draw each cage bar (minus the part that would enter the slit area)
    for (theta = [step/2:step:180-step/2]) {
      // Do not calculate/draw the bar if the bar begins within the slit area
      if ((R1+r1)*sin(theta) > real_slit_width/2) {
        // Compute arc length of this side bar
        distanceInSlit = (real_slit_width/2)/sin(theta);
        arcLength = acos(distanceInSlit/(R1+r1));
        rz(theta) rx(90) torus(R1+r1, r1, arcLength, spiked=spiked);
        rz(180+theta) rx(90) torus(R1+r1, r1, arcLength, spiked=spiked);
      }
    }
  }
}

module cage_lock() {
  // Create the solid arc that interfaces with the mating parts
  mount_arc();
  // Create the flat plane on which the mating parts slide
  mount_flat();
  // Create the cage's piece of the lock
  lock_dovetail_inner();
}

module lock_dovetail_inner() {
  inner_dovetail_length = mount_length/3 - part_margin;
  difference() {
    lock_case_shape(inner_dovetail_length);
    // Ensure the lock body does not enter the cage itself
    dz(-r3) skewxz(tan(tilt)) cylinder(r=R1+r3, h=100, center=true);
    // Cut a cavity for the lock module
    dx(-R1-r3-mount_width/2-lock_lateral) ry(tilt) dz(lock_vertical) dy(19-mount_length/2) {
      stealth_lock(lock_margin);
      rx(-90) cylinder(r=3.1+lock_margin, h=mount_length-19);
    }
  }
}

module lock_dovetail_outer() {
  intersection () {
    difference() {
      union() {
        dy(mount_length/3) lock_case_shape(mount_length/3, outer=true);
        my() dy(mount_length/3) lock_case_shape(mount_length/3, outer=true);
      }
      // Cut a cavity for the lock module
      sy(1.01) dx(-R1-r3-mount_width/2-lock_lateral) ry(tilt) dz(lock_vertical) dy(19-mount_length/2) {
        stealth_lock(lock_margin);
        rx(-90) cylinder(r=3.1+lock_margin, h=mount_length-19);
      }
    }
    union() {
       dz(-r3) skewxz(tan(tilt)) dz(-r3) mx() dx(R1+r3+mount_width/2 + part_margin) dy(-mount_length/2) rounded_cube([50, mount_length/3, mount_height*cos(tilt)+2*r3], rounding);
      my() dz(-r3) skewxz(tan(tilt)) dz(-r3) mx() dx(R1+r3+mount_width/2 + part_margin) dy(-mount_length/2) rounded_cube([50, mount_length/3, mount_height*cos(tilt)+2*r3], rounding);
    }
  }
  // Add a connecting block between the lock part and the base ring:
  hull() {
    dz(-2*r3) dy(-mount_length/2) mx() dx(R1+2*r3*sin(tilt)+part_margin) rounded_cube([base_lock_bridge_width, mount_length, r3-part_margin], (r3-part_margin)/2.01);
    dz(-gap) dx(-R1-r3-gap*sin(tilt)) rx(90) cylinder(r=r3/2, h=mount_length, center=true);
    dx(R2+2*r2-R1-r3-r2-gap*sin(tilt)) dz(-gap) rz(165) torus(R2+2*r2, r3/2, 30);
  }
}

// A hull of four rounded cylinders to create the main lock body. It extends down a bit more for the outer lock piece
module lock_case_shape(length, outer=false) {
  extra = outer ? r3 : 0;
  
  hull() {
    dx(-R1-r3-mount_width/2-lock_case_upper_radius+lock_case_lower_radius) dz(lock_case_lower_radius-r3-extra) rx(90) rounded_cylinder(lock_case_lower_radius, length, rounding, center=true);
    dx(-R1-r3-mount_width/2) dz(mount_height*cos(tilt) - lock_case_upper_radius) rx(90) rounded_cylinder(lock_case_upper_radius, length, rounding, center=true);
    dz(lock_case_lower_radius-r3-extra) rx(90) rounded_cylinder(lock_case_lower_radius, length, rounding, center=true);
    dz(mount_height*cos(tilt)-lock_case_lower_radius) rx(90) rounded_cylinder(lock_case_lower_radius, length, rounding, center=true);
  }
}

module mount_arc(arcLength=60) {
  skewxz(tan(tilt)) {
    rz(180-arcLength/2) {
      rotate_extrude(angle=arcLength) {
        dx(R1) offset(r=rounding) offset(delta=-rounding) square([cage_bar_thickness, mount_height*cos(tilt)]);
      }
      // Put smooth caps on the sides of the mount arc
      dx(R1+r1) rounded_cylinder(r1, mount_height*cos(tilt), rounding);
      rz(arcLength) dx(R1+r1) rounded_cylinder(r1, mount_height*cos(tilt), rounding);
    }
  }
}

module mount_flat() {
  dz(-r3) skewxz(tan(tilt)) difference() {
    translate([-R1-r3-mount_width/2, -mount_length/2, 0]) rounded_cube([mount_width, mount_length, mount_height*cos(tilt)+r3], rounding);
    cylinder(r=R1+r3, h=100);
  }
}

module base_ring() {
  if (wavyBase) {
    dz(-gap) dx(R2+r2-R1-r1-gap*tan(tilt)) wavy_torus(R2+r2, r2, waveAngle);
  } else {
    dz(-gap) dx(R2+r2-R1-r1-gap*tan(tilt)) torus(R2+r2, r2, spiked=base_spiked);
  }
}

module wavy_torus(R, r, pitch) {
  union() {
    translate([-sin(-45)*R*(1-cos(pitch)), 0, -R*sin(-45)*sin(pitch)]) ry(pitch) rz(-45) {
      torus(R, r, 90, spiked=base_spiked);
      dx(R) sphere(r);
    }
    translate([0, sin(45)*R*(1-cos(pitch)), -R*sin(45)*sin(pitch)]) rx(pitch) rz(45) {
      torus(R, r, 90, spiked=base_spiked);
      dx(R) sphere(r);
    }
    translate([-sin(135)*R*(1-cos(pitch)), 0, -R*sin(135)*sin(-pitch)]) ry(-pitch) rz(135) {
      torus(R, r, 90, spiked=base_spiked);
      dx(R) sphere(r);
    }
    translate([0, sin(-135)*R*(1-cos(pitch)), -R*sin(-135)*sin(-pitch)]) rx(-pitch) rz(-135) {
      torus(R, r, 90, spiked=base_spiked);
      dx(R) sphere(r);
    }
  }
}