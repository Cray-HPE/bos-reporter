#
# MIT License
#
# (C) Copyright 2022-2024 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

"""
BOS common library
"""

# Standard imports
import datetime
import re
import traceback

# TIME_DURATION_PATTERN is also defined in the bos repository.
# If this ever needs to be changed, also determine if it should be changed there as well.
TIME_DURATION_PATTERN = re.compile(r"^(\d+?)(\D+?)$", re.M|re.S)

# duration_to_timedelta is also defined in the bos repository.
# If this ever needs to be changed, also determine if it should be changed there as well.
def duration_to_timedelta(timestamp: str) -> datetime.timedelta:
    """
    Converts a <digit><duration string> to a timedelta object.
    """
    # Calculate the corresponding multiplier for each time value
    seconds_table = {'s': 1,
                     'm': 60,
                     'h': 60*60,
                     'd': 60*60*24,
                     'w': 60*60*24*7}
    timeval, durationval = TIME_DURATION_PATTERN.search(timestamp).groups()
    timeval = float(timeval)
    seconds = timeval * seconds_table[durationval]
    return datetime.timedelta(seconds=seconds)

# exc_type_msg is also defined in the bos repository.
# If this ever needs to be changed, also determine if it should be changed there as well.
def exc_type_msg(exc: Exception) -> str:
    """
    Given an exception, returns a string of its type and its text
    (e.g. TypeError: 'int' object is not subscriptable)
    """
    return ''.join(traceback.format_exception_only(type(exc), exc))
