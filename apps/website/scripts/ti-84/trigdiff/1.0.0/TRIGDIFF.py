ITEMS = [
    ("sin(x)", "cos(x)", ["-cos(x) + C"]),
    ("cos(x)", "-sin(x)", ["sin(x) + C"]),
    ("-sin(x)", "-cos(x)", ["cos(x) + C"]),
    ("-cos(x)", "sin(x)", ["-sin(x) + C"]),
    ("tan(x)", "sec(x)²", ["ln|sec(x)| + C", "= -ln|cos(x)| + C"]),
    ("sec(x)", "sec(x)*tan(x)", ["ln|sec(x)+tan(x)| + C"]),
    ("csc(x)", "-csc(x)*cot(x)", ["-ln|csc(x)+cot(x)| + C"]),
    ("cot(x)", "-csc(x)²", ["ln|sin(x)| + C", "= -ln|csc(x)| + C"]),
]

MENU_PAGE = 4


def show_menu_page(start):
    end = min(start + MENU_PAGE, len(ITEMS))

    print("Trigonometry")
    print("Derivatives / Antiderivatives")
    print("")

    for i in range(start, end):
        print("{}) {}".format(i + 1, ITEMS[i][0]))

    print("")
    print("n) Next  p) Prev  0) Quit")


def show_item(i):
    f, df, F_lines = ITEMS[i]
    print("")
    print("Function:\n  f(x) = {}".format(f))
    print("")
    print("Derivative:\n  d/dx f(x) = {}".format(df))
    print("")
    print("Antiderivative:")
    for line in F_lines:
        print("  {}".format(line))
    print()


def main():
    start = 0
    while True:
        show_menu_page(start)
        print("")
        print("Choice? ", end="")
        s = input().strip().upper()
        if s == "0":
            print("Bye.")
            break
        if s == "N":
            start += MENU_PAGE
            if start >= len(ITEMS):
                start = 0
            continue
        if s == "P":
            start -= MENU_PAGE
            if start < 0:
                last = ((len(ITEMS) - 1) // MENU_PAGE) * MENU_PAGE
                start = max(0, last)
            continue
        if s.isdigit():
            k = int(s)
            if 1 <= k <= len(ITEMS):
                show_item(k - 1)
                print("Enter to continue...", end="")
                _ = input()
                continue
        print("Invalid choice.")
        print("Press Enter to continue ...", end="")
        _ = input()


main()
