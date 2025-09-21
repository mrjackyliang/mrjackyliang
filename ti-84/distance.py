import math


def main():
    labels = ("X1", "Y1", "X2", "Y2")
    inputs = []

    print("Distance Between Two Points")
    print("({}, {}) and ({}, {})".format(labels[0], labels[1], labels[2], labels[3]))
    print("")

    while len(inputs) < 4:
        user_input = input(labels[len(inputs)] + ": ")
        try:
            number_input = float(user_input)
            inputs.append(number_input)
        except ValueError:
            print("\"{}\" is not a number".format(user_input))

    result = math.sqrt((inputs[2] - inputs[0]) ** 2 + (inputs[3] - inputs[1]) ** 2)
    print("Distance: {}".format(result))


main()
