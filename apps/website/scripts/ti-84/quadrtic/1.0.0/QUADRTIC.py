import math


def solve_quadratic(a, b, c):
    if a == 0:
        if b == 0:
            if c == 0:
                return "Infinite solutions", ()
            return "No solution", ()
        return "Linear solution", (-c / b,)

    d = b * b - 4 * a * c

    if d < 0:
        return "No real roots", ()
    elif d == 0:
        x = -b / (2 * a)

        return "One real root", (x, x)
    else:
        sqrt_d = math.sqrt(d)
        r1 = (-b + sqrt_d) / (2 * a)
        r2 = (-b - sqrt_d) / (2 * a)

        return "Two real roots", (r1, r2)


def main():
    try:
        print("Quadratic Equation Solver")
        print("Solve a*x² + b*x + c = 0")
        print("")

        a = float(input("a? "))
        b = float(input("b? "))
        c = float(input("c? "))

        desc, roots = solve_quadratic(a, b, c)

        print(desc)

        if roots:
            for x in roots:
                print(x)
    except Exception as error:
        print("Error:", error)


main()
