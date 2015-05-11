import random

target = open("data.mif", 'w')
target.truncate()

train = open("../java/train", 'w')
train.truncate()

dev = open("../java/dev", 'w')
dev.truncate()

train.write("label\n");
dev.write("label\n");

parameters = []
parameters.append(random.random()/5 + .15)
parameters.append(random.random()/5 + .15)
parameters.append(random.random()/5 + .15)
parameters.append(random.random()/5 + .15)

trains = 200;
tests = 10;
depth = 200 * 5 + 10 * 4 + 2;

target.write("DEPTH = " + str(depth) + ";\n");
target.write("WIDTH = 32;\n");
target.write("ADDRESS_RADIX = HEX;\n");
target.write("DATA_RADIX = HEX;\n");
target.write('\n');
target.write("CONTENT BEGIN\n");
target.write('\n');

size = 0;

val = "%08x" % trains
index = "%03x" % size
size+=1
target.write(index + " : " + val + ";\n")

val = "%08x" % tests
index = "%03x" % size
size+=1
target.write(index + " : " + val + ";\n")

for i in range(0, trains):
    sum = 0;
    for j in range(0, 4):
        value = random.random()
        val = "%08x" % (int)(value * 65536)
        index = "%03x" % size
        size+=1
        target.write(index + " : " + val + ";\n")
        train.write(str(value) + ",")
        sum += value * parameters[j];
    if(sum < .5):
        output = 0
    else:
        output = 1
    val = "%08x" % (int)(output * 65536)
    index = "%03x" % size
    size+=1
    target.write(index + " : " + val + ";\n")
    train.write(str(output) + '\n')

for i in range(0, tests):
    sum = 0
    for j in range(0, 4):
        value = random.random()
        val = "%08x" % (int)(value * 65536)
        index = "%03x" % size
        size+=1
        target.write(index + " : " + val + ";\n")
        dev.write(str(value) + ",")
        sum += value * parameters[j];
    if(sum < .5):
        output = 0
    else:
        output = 1
    dev.write(str(output) + '\n')
        
target.write("\nEND;\n")

print "And finally, we close it."
target.close()
