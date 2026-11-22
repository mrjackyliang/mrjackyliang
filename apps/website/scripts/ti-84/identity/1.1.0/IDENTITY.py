SECTIONS = [
    ("Pythagorean Theorem", [
        "sin^{2}(x) + cos^{2}(x) = 1",
        "1 + tan^{2}(x) = sec^{2}(x)",
        "1 + cot^{2}(x) = csc^{2}(x)",
    ]),
    ("Integration By Parts", [
        "int u dv = uv - int v du",
        "Clue: Choose 'u' using LIPET",
        "   L: ln x, log x",
        "   I: arcsin(x), arctan(x)",
        "   P: x^{2}, sqrt(x)",
        "   E: e^{x}, 2^{x}",
        "   T: sin(x), cos(x)",
    ]),
    ("Basic Exponential Integral", [
        "int e^{at} dt",
        "= (1 / a) e^{at} + C",
    ]),
    ("Inverse Tangent Function", [
        "int (1 / x^{2} + a^{2})",
        "= (1 / a) arctan(x / a) + C"
    ]),
    ("Trig Sub: a^{2} - x^{2}", [
        "sqrt(a^{2} - x^{2})",
        "   x = a sin(t)",
        "  dx = a cos(t) dt",
        "",
        "identity: 1 - sin^{2} = cos^{2}",
    ]),
    ("Trig Sub: a^{2} + x^{2}", [
        "sqrt(a^{2} + x^{2})",
        "   x = a tan(t)",
        "  dx = a sec^{2}(t) dt",
        "",
        "identity: 1 + tan^{2} = sec^{2}",
    ]),
    ("Trig Sub: x^{2} - a^{2}", [
        "sqrt(x^{2} - a^{2})",
        "   x = a sec(t)",
        "  dx = a sec(t) tan(t) dt",
        "",
        "identity: sec^{2} - 1 = tan^{2}",
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
    print("0) Next  00) Prev  000) Quit")


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
            start += MENU_PAGE
            if start >= len(SECTIONS):
                start = 0
        elif s == "00":
            start -= MENU_PAGE
            if start < 0:
                last = ((len(SECTIONS) - 1) // MENU_PAGE) * MENU_PAGE
                start = max(0, last)
        elif s == "000":
            print("Bye.")
            break
        elif s.isdigit():
            k = int(s)
            if 1 <= k <= len(SECTIONS):
                show_section(k - 1)
        else:
            print("Invalid choice.")
            print("Press Enter to continue ...", end="")
            _ = input()


main()
