import math

labels = ("X1", "Y1", "X2", "Y2")
inputs = []

print("Distance Between Two Points")
print("({}, {}) and ({}, {})".format(labels[0], labels[1], labels[2], labels[3]))
print("")

while len(inputs) < 4:
    userInput = input(labels[len(inputs)] + ": ")

    try:
        numberInput = float(userInput)
        inputs.append(numberInput)
    except ValueError:
        print("\"{}\" is not an integer".format(userInput))

result = math.sqrt(math.pow((inputs[2] - inputs[0]), 2) + math.pow((inputs[3] - inputs[1]), 2))

print("Distance: {}".format(result))
