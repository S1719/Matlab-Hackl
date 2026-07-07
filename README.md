# Matlab Hackl-Glac

Simulink model for setting the current setpoint of a permanent magnet synchronous motor (PMSM) based on the operating point.

This repository contains a Simulink model that calculates the required currents `id*` and `id*` for the operating point based on the desired torque `T*` and the desired speed `n*`.

  
## Operating Point Selection Algorithm
The analytical characteristic curves MTPC, MTPV, and MTPF are calculated based on the work of Christoph M. Hackl.
The selection algorithm used in the model, based on the work of Glac, Šmídl, and Peroutka, essentially follows this procedure:
1. Calculation of the relevant curves and intersection points.
2. Determination of the sign of the reference torque.
3. Calculation of candidate points at the intersections of MTPC, MTPV, the current loop, the voltage ellipse, and the torque hyperbola.
4. Identification of a feasible intermediate candidate \(i_{feas}\).
5. Comparison of the required torque with the torques achievable at the boundary points.
6. Selection of the final operating point as one of the feasible candidates, e.g., \(i_{feas}\), \(i_{tv}\), or \(i_{at}\), depending on voltage, current, and torque limits. 


## Reference

Mathematical derivations of the MTPC, MTPV, and MTPF curves (Eldeeb, Hackl): https://www.researchgate.net/publication/309738085_On_the_optimal_feedforward_torque_control_problem_of_anisotropic_synchronous_machines_Quadrics_quartics_and_analytical_solutions

Selection procedure for the final operating point (Glac, Šmídl, Peroutka): https://www.researchgate.net/publication/330487741_Optimal_Feedforward_Torque_Control_of_Synchronous_Machines_with_Time-Varying_Parameters


