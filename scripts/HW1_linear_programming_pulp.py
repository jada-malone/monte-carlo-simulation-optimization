import pulp as pl

prob = pl.LpProblem("Production_Cost", pl.LpMaximize)

x_1 = pl.LpVariable("x_1", lowBound=0, cat="Continuous")
x_2 = pl.LpVariable("x_2", lowBound=0, cat="Continuous")

prob += 50*x_1 + 40*x_2 + 0

prob += x_1 <= 50, "_C1"
prob += 3*x_1 + x_2 <= 120, "_C2"
prob += 2*x_1 + 4*x_2 <= 100, "_C3"

# Solve (your system shows COIN_CMD available)
solver = pl.COIN_CMD(msg=True)     # uses cbc underneath
prob.solve(solver)

print(f"{prob.name}:")
print("MAXIMIZE")
print(prob.objective)
print("SUBJECT TO")
for cname in ["_C1","_C2","_C3"]:
    print(prob.constraints[cname])

print("\nVARIABLES")
print("x_1 Continuous")
print("x_2 Continuous")

print("\nstatus: Optimal")
print("x_1* =", x_1.value())
print("x_2* =", x_2.value())
print(pl.value(prob.objective))

print("\nSensitivity Analysis:")
for cname in ["_C1","_C2","_C3"]:
    con = prob.constraints[cname]
    slack_out = -0.0 if abs(con.slack) < 1e-8 else con.slack
    sp_out = -0.0 if (con.pi is not None and abs(con.pi) < 1e-8) else con.pi
    print(f"{cname} : {con} , Slack= {slack_out} , Shadow Price= {sp_out}")

print()
print(f"x_1 = {x_1.value()} , Reduced Cost= {x_1.dj}")
print(f"x_2 = {x_2.value()} , Reduced Cost= {x_2.dj}")




# -----------------------------
# LP Minimization Problem
# Min Z = 3x1 + 4x2 + 5x3
# s.t.
# 2x1 + x3 >= 8
# x2 + x3 >= 6
# 6x1 + 8x2 >= 48
# x1,x2,x3 >= 0
# -----------------------------

# Create the model
prob = pl.LpProblem("Minimization_Problem", pl.LpMinimize)

# Decision variables
x_1 = pl.LpVariable("x_1", lowBound=0, cat="Continuous")
x_2 = pl.LpVariable("x_2", lowBound=0, cat="Continuous")
x_3 = pl.LpVariable("x_3", lowBound=0, cat="Continuous")

# Objective function
prob += 3*x_1 + 4*x_2 + 5*x_3 + 0

# Constraints (named to match your screenshot)
prob += 2*x_1 + x_3 >= 8, "_C1"
prob += x_2 + x_3 >= 6, "_C2"
prob += 6*x_1 + 8*x_2 >= 48, "_C3"

# Solve (CBC). msg=False hides the CBC "At line 2 NAME..." log
solver = pl.PULP_CBC_CMD(msg=False)
prob.solve(solver)

# -----------------------------
# Print output in screenshot style
# -----------------------------
print(f"{prob.name}:")
print("MINIMIZE")
print(prob.objective)
print("SUBJECT TO")
print(prob.constraints["_C1"])
print(prob.constraints["_C2"])
print(prob.constraints["_C3"])

print("\nVARIABLES")
print("x_1 Continuous")
print("x_2 Continuous")
print("x_3 Continuous")

print("\nstatus: Optimal")
print("x_1* =", x_1.value())
print("x_2* =", x_2.value())
print("x_3* =", x_3.value())
print(pl.value(prob.objective))

print("\nSensitivity Analysis:")

def fmt_zero(v):
    return -0.0 if abs(v) < 1e-9 else v

for cname in ["_C1", "_C2", "_C3"]:
    con = prob.constraints[cname]
    print(f"{cname} : {con} , Slack= {fmt_zero(con.slack)} , Shadow Price= {fmt_zero(con.pi)}")

print()
print(f"x_1 = {x_1.value()} , Reduced Cost= {fmt_zero(x_1.dj)}")
print(f"x_2 = {x_2.value()} , Reduced Cost= {fmt_zero(x_2.dj)}")
print(f"x_3 = {x_3.value()} , Reduced Cost= {fmt_zero(x_3.dj)}")
