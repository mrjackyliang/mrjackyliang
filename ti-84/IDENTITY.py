SECTIONS = [
    ("Pythagorean", [
        "sin²x + cos²x = 1",
        "1 + tan²x = sec²x",
        "1 + cot²x = csc²x",
    ]),
    ("Reciprocal", [
        "sin(x) = 1/csc(x)",
        "cos(x) = 1/sec(x)",
        "tan(x) = 1/cot(x)",
        "csc(x) = 1/sin(x)",
        "sec(x) = 1/cos(x)",
        "cot(x) = 1/tan(x)",
    ]),
    ("Even / Odd", [
        "sin(-x) = -sin(x)   (odd)",
        "cos(-x) =  cos(x)   (even)",
        "tan(-x) = -tan(x)   (odd)",
        "csc(-x) = -csc(x)   (odd)",
        "sec(-x) =  sec(x)   (even)",
        "cot(-x) = -cot(x)   (odd)",
    ]),
    ("Double-angle", [
        "sin(2x) = 2 sin(x) cos(x)",
        "cos(2x) = cos²x - sin²x",
        "        = 2 cos²x - 1",
        "        = 1 - 2 sin²x",
        "tan(2x) = 2 tan(x) / (1 - tan²x)",
    ]),
    ("Half-angle / Power reduction", [
        "sin²x = (1 - cos(2x)) / 2",
        "cos²x = (1 + cos(2x)) / 2",
    ]),
    ("Product-to-sum", [
        "sin A cos B",
        " = 1/2 [ sin(A+B) + sin(A-B) ]",
        "cos A cos B",
        " = 1/2 [ cos(A+B) + cos(A-B) ]",
        "sin A sin B",
        " = 1/2 [ cos(A-B) - cos(A+B) ]",
    ]),
    ("Inverse-trig derivatives", [
        "d/dx arcsin(x)",
        " = 1 / sqrt(1 - x²)",
        "d/dx arccos(x)",
        " = -1 / sqrt(1 - x²)",
        "d/dx arctan(x)",
        " = 1 / (1 + x²)",
        "",
        "d/dx arccsc(x)",
        " = -1 / ( |x| sqrt(x² - 1) )",
        "d/dx arcsec(x)",
        " = 1 / ( |x| sqrt(x² - 1) )",
        "d/dx arccot(x)",
        " = -1 / (1 + x²)",
        "",
    ]),
    ("Trig substitution patterns", [
        "sqrt(a² - x²):",
        "  x = a sin(t)",
        " dx = a cos(t) dt",
        "",
        " identity: 1 - sin² = cos²",
        "",
        "",
        "sqrt(a² + x²):",
        "  x = a tan(t)",
        " dx = a sec²(t) dt",
        "",
        " identity: 1 + tan² = sec²",
        "",
        "",
        "sqrt(x² - a²):",
        "  x = a sec(t)",
        " dx = a sec(t)tan(t) dt",
        "",
        " identity: sec² - 1 = tan²",
        "",
        "",
    ]),
    ("Exponential (Euler) forms", [
        "e^(i x)",
        " = cos(x) + i sin(x)",
        "cos(x)",
        " = (e^(i x) + e^(-i x)) / 2",
        "sin(x)",
        " = (e^(i x) - e^(-i x)) / (2 i)",
    ]),
]

MENU_PAGE = 4
TEXT_PAGE = 7


def clear():
    print("\n" * 2)


def pause(msg="Enter = more, 0 = back: "):
    print(msg, end="")
    return input().strip().upper()


def show_menu_page(start):
    end = min(start + MENU_PAGE, len(SECTIONS))

    print("Calculus I/II")
    print("Trig & Core Identities")
    print("")

    for i in range(start, end):
        print("{}) {}".format(i + 1, SECTIONS[i][0]))

    print("")
    print("n) Next  p) Prev  0) Quit")


def show_section(idx):
    title, lines = SECTIONS[idx]
    start = 0

    while True:
        clear()
        print(title)
        print("")
        end = min(start + TEXT_PAGE, len(lines))
        for ln in lines[start:end]:
            print(ln)

        print("")

        if len(lines) <= TEXT_PAGE:
            if pause("0 = back: ") == "0":
                return
        else:
            cmd = pause("n = more, p = prev, 0 = back: ")
            if cmd == "0":
                return
            elif cmd == "N":
                start = end if end < len(lines) else 0
            elif cmd == "P":
                start = max(0, start - TEXT_PAGE)


def main():
    start = 0

    while True:
        clear()
        show_menu_page(start)
        print("")
        print("Choice? ", end="")
        s = input().strip().upper()

        if s == "0":
            print("Bye.")
            break
        elif s == "N":
            start += MENU_PAGE
            if start >= len(SECTIONS):
                start = 0
        elif s == "P":
            start -= MENU_PAGE
            if start < 0:
                last = ((len(SECTIONS) - 1) // MENU_PAGE) * MENU_PAGE
                start = max(0, last)
        elif s.isdigit():
            k = int(s)
            if 1 <= k <= len(SECTIONS):
                show_section(k - 1)
        else:
            print("Invalid choice.")
            print("Press Enter to continue ...", end="")
            _ = input()


main()
