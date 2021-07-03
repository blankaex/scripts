'''
timestamp shifting script for my boi kme

assumptions:
    timestamps will always be in the format HH:MM:SS
    resulting timestamps will be between 00:00:00 and 24:00:00 (will wrap)
'''

import argparse, datetime, re, sys

# collect cli args
parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input', metavar='FILENAME',
        help='name of input file (REQUIRED)', required=True)
parser.add_argument('-o', '--output', metavar='FILENAME',
        help='name of output file, default is FILENAME-shifted')
parser.add_argument('-s', '--shift', metavar='TIME', type=int, default=20,
        help='amount to shift by in seconds, default is 20. can be negative')
parser.add_argument('--hours', action='store_true', default=False,
        help='use hh:mm:ss as timestamp format instead of mm:ss')
args = parser.parse_args()

# don't need to do anything to shift by 0 :wewdako:
if args.shift == 0:
    sys.exit('Nothing to do.')
    
# are we adding or subtracting?
add = True if args.shift > 0 else False

# get the shift amount
shift = datetime.timedelta(seconds=abs(args.shift))

# initialize list to write to output at the end
buffer = list()

# timestamp pattern to match
regex = '\d\d:\d\d' if not args.hours else '\d\d:\d\d:\d\d' 
pattern = '%M:%S' if not args.hours else '%H:%M:%S'

# open the input file and shift all the timestamps
# store lines to output in buffer
try:
    with open(args.input, 'r') as script:
        for line in script:
            matches = re.findall(regex, line)
            for match in matches:
                timestamp = datetime.datetime.strptime(match, pattern)
                newtime = timestamp + shift if add else timestamp - shift
                line = line.replace(match, newtime.strftime(pattern))
            buffer.append(line)
except FileNotFoundError:
    sys.exit('Unable to open {}. Does the file exist?'.format(args.input))
except PermissionError:
    sys.exit('Unable to open {}. Check your file permissions.'.format(args.input))
except:
    sys.exit('Something broke, send Blank input file that caused this error :pepeg:')

# use default output filename if not specified
if not args.output:
    tokens = args.input.rsplit('.', 1)
    if len(tokens) == 1:
        args.output = tokens[0] + '-shifted.out'
    else:
        args.output = tokens[0] + '-shifted.' + tokens[1]

# dump buffer to output file
try:
    with open(args.output, 'w') as output:
        output.writelines(buffer)
        print("Shifted script written to {}.".format(args.output))
except:
    sys.exit('Unable to open {}.'.format(args.output))
