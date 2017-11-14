import os.path
import sys
import re
import argparse

parser = argparse.ArgumentParser()

subparsers = parser.add_subparsers(help='sub-command help')

parser_a = subparsers.add_parser('auto_gen', help='generate in auto mode using svcf')
parser_a.add_argument('input', help='input verilog file with chipscope instance')
parser_a.add_argument('input_svcf', help='input simvision waveform file')
parser_a.add_argument('-o', '--output', help='output file name == input by default')

parser_b = subparsers.add_parser('user_gen', help="generate from user verilog file")
parser_b.add_argument('input', help='input user verilog file')
parser_b.add_argument('-o', '--output', help='output file name == input by default')

parser_c = subparsers.add_parser('make_templ', help="generate verilog template for user")
parser_c.add_argument('input', help='input verilog file with chipscope instance')
parser_c.add_argument('-o', '--output', help='output file name == input by default')
mode = sys.argv[1]
args = parser.parse_args()
verilog_filename = args.input
if mode == 'auto_gen':
    waveform_filename = args.input_svcf
if args.output:
    output_filename = args.output
else:
    output_filename = args.input.split('.')[0]

chipscope_signals = []  # here we will store bus/signal - width pair
verilog_templ = []
# structure to store chipscope signals attributes


class ChipscopeSignal(object):
    def __init__(self, name):
        self.name = name
    pass


def find_chipscope_inst(filename):
    with open(filename, 'r') as f:
        for string in f:
            if re.findall(r'chipscope_icon chipscope_icon', string):
                print(string)
                if mode == 'make_templ':
                    verilog_templ.append(string)
                print("Chipscope instance was found. continue searching for data bus...")
                break
        else:
            print("Chipscope instance was not found. ERROR!")
            sys.exit(1)

        for string in f:
            if re.findall(r'assign data = {', string):
                print(string)
                if mode == 'make_templ':
                    verilog_templ.append(string)
                print("Chipscope data bus was found, start parsing it...")

                break
        else:
            print(string)
            print("Chipscope data bus was not found. ERROR!")
            sys.exit(1)

        for string in f:
            result = re.findall(r'\w+', string)
            if mode == 'make_templ':
                verilog_templ.append(string)
            if result:
                chipscope_signals.append(ChipscopeSignal(result[0]))
            if '};' in string:
                print("Found end of the chipscope data bus. End parsing")
                break


def calc_size_from_svcf(bus_name):
    with open(waveform_filename, 'r') as f:
        for string in f:
            if bus_name in string:
                break
        else:
            print("Cannot find bus name in waveform file. ERROR!")
            sys.exit(1)
        str_size = string.split(bus_name)[1]
        if str_size[0] == '}':
            return 1
        else:
            str_numbers = str_size.split(':')
            number1 = int(re.findall(r'\d+', str_numbers[0])[0])
            number2 = int(re.findall(r'\d+', str_numbers[1])[0])
            return number1 - number2 + 1


def calc_size_from_user(bus_name):
    with open(verilog_filename, 'r') as f:
        for string in f:
            if bus_name in string:
                break
        else:
            print("Cannot find bus name in user file. ERROR!")
            sys.exit(1)
        if ':' in string:
            numbers = re.findall(r'\d+', string)
            if len(numbers) < 2 or len(numbers) > 3:
                print(len(numbers))
                print(string)
                print("You do not substitute parameters in template file. ERROR")
                sys.exit(1)
            else:
                if len(numbers) == 3:
                    number1, number2, number3 = numbers
                elif len(numbers) == 2:
                    number1, number3 = numbers
                    number2 = 0
            return int(number1) - int(number2) - int(number3) + 1
        else:
            return 1

#====================always do this

find_chipscope_inst(verilog_filename)

if mode == 'auto_gen':

    for item in chipscope_signals:
        item.size = calc_size_from_svcf(item.name)

elif mode == 'user_gen':
    for item in chipscope_signals:
        item.size = calc_size_from_user(item.name)

elif mode == 'make_templ':
    with open(output_filename + '.v', 'w') as f_w:
        for item in chipscope_signals:
            with open(verilog_filename, 'r') as f_r:
                for string in f_r:
                    result = re.findall('((output|input|wire|reg) .+'+item.name+')', string)
                    if result:
                        print(result[0][0])
                        f_w.write(result[0][0] + '\n')
                        break
                else:
                    print("Cannot find definition of {0} signal. ERROR!".format(item.name))
                    sys.exit(1)
        f_w.write('\n')
        for templ_str in verilog_templ:
            f_w.write(templ_str)
    print('Generation of verilog template was succesfull!')
    sys.exit(0)



chipscope_signals.reverse()

pointer = 0
for item in chipscope_signals:
    item.pointer = pointer
    pointer += item.size

size_sum = 0
chipscope_signals_voc = {}
for item in chipscope_signals:
    chipscope_signals_voc[item.pointer] = item
    size_sum += item.size
    print('{0}'.format([item.name, item.size, item.pointer]))

print("Total signals count: {0}".format(len(chipscope_signals)))

if size_sum > 1028:
    print("Bus size is bigger then chipscope capacity. ERROR")
    sys.exit(1)

bus_block_template = """unit.0.0.port.-1.b.$num.alias=$name
unit.0.0.port.-1.b.$num.channellist=$list
unit.0.0.port.-1.b.$num.color=java.awt.Color[r\=0,g\=0,b\=124]
unit.0.0.port.-1.b.$num.name=$name
unit.0.0.port.-1.b.$num.orderindex=-1
unit.0.0.port.-1.b.$num.radix=Hex
unit.0.0.port.-1.b.$num.signedOffset=0.0
unit.0.0.port.-1.b.$num.signedPrecision=0
unit.0.0.port.-1.b.$num.signedScaleFactor=1.0
unit.0.0.port.-1.b.$num.tokencount=0
unit.0.0.port.-1.b.$num.unsignedOffset=0.0
unit.0.0.port.-1.b.$num.unsignedPrecision=0
unit.0.0.port.-1.b.$num.unsignedScaleFactor=1.0
unit.0.0.port.-1.b.$num.visible=1
"""
signal_block_template = """unit.0.0.port.-1.s.$num.alias=$alias
unit.0.0.port.-1.s.$num.color=java.awt.Color[r\=0,g\=0,b\=124]
unit.0.0.port.-1.s.$num.name=DataPort[$num]
unit.0.0.port.-1.s.$num.orderindex=-1
unit.0.0.port.-1.s.$num.visible=$visible
"""

waveform_signal_template = """unit.0.0.waveform.posn.$posn.channel=$chan_num
unit.0.0.waveform.posn.$posn.name=DataPort[$chan_num]
unit.0.0.waveform.posn.$posn.type=signal
"""

waveform_bus_template = """unit.0.0.waveform.posn.$posn.channel=2147483646
unit.0.0.waveform.posn.$posn.name=$name
unit.0.0.waveform.posn.$posn.radix=1
unit.0.0.waveform.posn.$posn.type=bus
"""

# Start forming cpj file

with open("template.cpj", 'r') as templ:
    with open(output_filename + '.cpj', 'w') as f:
        # copy first part of the template
        for i in range(83):
            f.write(templ.readline())
        bus_cnt = 0
        # Filling bus section:
        for item in chipscope_signals:
            if item.size != 1:
                row = [str(x) for x in range(item.pointer, item.pointer + item.size)]
                row = ' '.join(row)
                bus_block_template_name = bus_block_template.replace('$name', item.name)
                f.write(bus_block_template_name.replace('$list', row).replace('$num', str(bus_cnt)))
                bus_cnt += 1

        templ_rdl = templ.readline()
        f.write(templ_rdl.replace('=0', '=' + str(bus_cnt)))

        f.write(templ.readline())

        signal_fl = [False for x in range(1024)]

        for item in chipscope_signals:
            if item.size == 1:
                signal_fl[item.pointer] = True
        # Filling signals section:
        for i in range(1024):
            if signal_fl[i]:
                signal_visible = '1'
                signal_alias = chipscope_signals_voc[i].name
            else:
                signal_visible = '0'
                signal_alias = ''
            f.write(signal_block_template.replace('$num', str(i)).replace('$alias', signal_alias).replace('$visible',
                                                                                                          signal_visible))
        #  Just copy another part of the template
        for i in range(95):
            f.write(templ.readline())

        f.write(templ.readline().replace('1024', str(len(chipscope_signals))))

        # Forming waves:
        for i, item in enumerate(chipscope_signals):
            if item.size == 1:
                f.write(waveform_signal_template.replace('$posn', str(i)).replace('$chan_num', str(item.pointer)))
            else:
                f.write(waveform_bus_template.replace('$posn', str(i)).replace('$name', item.name))
print("Generating {0}.cpj file is done!".format(output_filename))
