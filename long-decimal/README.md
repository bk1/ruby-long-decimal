Version
-------

This version (1.00.02) is fixing bugs from version 1.00.01.
It also can be considered as a release candidate from the upcoming
version 1.01.00, adding new features.

Improvements over the previous version:

- migration from CVS (rubyforge) to GIT (github)
- bug fixed with frozen string attempted to be changed when parsing a string for a long-decimal number.
- removed some code duplication between rounding of LongDecimal, LongDecimalQuot and rounding of Integers to remainder set.
- added more rounding modes based on geometric, harmonic, quadratic and cubic mean
- fixed calculation of powers in such a way that it fails yielding a reasonably accurate result less often.  Cases that are sensitive are powers with a base that is close to 1 (for example off by 1e-35) with an exponent that is huge (for example like 1e20).  With "reasonable" values power of a LongDecimal by a LongDecimal works quite well.
- added functions to calculate arithmetic, harmonic, quadratic, cubic, geometric, arithmetic-geometric and harmonic-geometric means.
- added functions to round summand in such a way that their sum is the rounded value of the sum of the unrounded values (experimental)
- moved power, log10, log2 etc. from long-decimal-extra.rb to long-decimal.rb
- added more unit tests

Work to do for 1.01.00:
- go through functions that are working with rounding modes as parameter (like transcendental functions, sqrt, cbrt etc.) to ensure that they work properly with all new rounding modes
- improve algorithm for rounding with sum constraint
- go through unit tests to see they are covering all rounding modes
- add unit tests for rounding with sum constraint
- rubydoc-documentation
- external documentation

Work to do for 1.02.00 (or 2.00.00):
- add the following transcendental functions: sin, cos, tan, cot, sec, csc, sinh, cosh, tanh, coth, sech, csch, asin, acos, atan, atan2, acot, asec, acsc, asinh, acosh, atanh, acoth, asech, acsch
- documentation
- external documentation
- interoperability with flt

The existing functionality did not show any bugs during intensive
testing, so it could be assumed that the whole library is good for
for production/stable.  The library is used for productive software by the author.

This software development effort is hosted on GitHub ( https://github.com/ )
under the project name "long-decimal", to be
found directly with http://rubyforge.org/projects/long-decimal/
So you should feel encouraged to look if there is a newer version, when
you install long-decimal.

This version is an production stable version.
Operations +, -, *, / and sqrt should be working properly
and justify calling this release production/stable.
Even log and exp should be fine.  log, log2, log10 and exp have been
tested for several million random values and the current version
should cover all of these correctly.  But it is still possible, that
in some cases the result deviates in the last digit by 1 or 2 from the
required result.  A deviation of slightly more than half of the unit of
the last digit is already present.  Improving on this would require an
extensive extension of internal functionality to provide rounding
information in case of last digits being 50000..., where additional
digits would reveal if this really needs to be rounded up or down.
Because these functions are transcendental, at least exp and log will
always have either one of these true, it will never be exactly ....5.
Speed could be improved as well.

It would be a good idea to do some more mathematical analysis on how
many digits are needed internally to guarantee the correctness of the
digits that are provided.  But this will not be considered a
requirement for the next versions to come.

A unique feature of long-decimal is the method
round_to_allowed_remainders().  This can be used for financial
calculations, where the last digit is required to be 0 or 5, which can
be achieved by calling
l.round_to_allowed_remainders([0, 5], 10, LongDecimalRoundingMode::ROUND_HALF_UP)
But this has been defined and developed in a more generic way, so the
modulus (here 10) and the set of allowed digits can be chosen
abritrarily, in which case the integral number, that is obtained by
disregarding the decimal point, is rounded in such a way that its
remainder modulo the modulus is in the list of allowed remainders,
after which the decimal point is inserted again.

Usage
-----

require 'long-decimal'

(then use it.)

Test
----

Some runit tests have been included.  They give some indication of the
correctness of this library and allow changes to be checked in order
to make sure that what was running before would still work afterwards.
Tests for a library as complex as long-decimal can never be
exhaustive, but they give a good indication that methods are working
correctly.  The set of tests that is available now is considered to be
complete.  As a policy a release is not created unless all tests
succeed.  Running all tests can take a few minutes or even hours,
depending on your machine.  Whatever is gained by making the software
run faster is used up again by adding more tests.  The regular tests are run by

ruby test/testlongdecimal.rb

This is the result of the test:

Finished in 5174.187655 seconds.
134 tests, 9461909 assertions, 0 failures, 0 errors

In addition random tests for exp, exp2, exp10, sqrt, log, log2 and
log10 can be run for a long time, using

ruby test/testrandom.rb.

The functionality in lib/long-decimal-extra.rb, which contains some
more advanced and less tested methods, has its tests in

ruby test/testlongdecimal-extra.rb

and its random tests in

ruby test/testrandom-extra.rb

This is the result of the test:

Finished in 4115.851979 seconds.
12 tests, 976 assertions, 0 failures, 0 errors

Likewise tests for powers x to the yth with random x and y (which also
resided in long-decimal-extra.rb) can be tested for a long time using

ruby test/testrandpower.rb

These random tests require installation of the ruby-library
crypt-isaac for its random numbers, which works well with Linux or
Windows in combination with Cygwin.  Installation of crypt-isaac is
required for the random tests.

If you actually want to run tests for long-decimal or
long-decimal-extra and find an error with it, please report it.

Install
-------


1. Using ruby-gems (preferred)
- open a shell window
- become root, unless the current user has the right to install gems
  (which is usually the case on windows)

  su

- uninstall old versions

  gem uninstall long-decimal

- install the newest version

  gem install long-decimal

- Usage from your ruby-programs:

  require "long-decimal"

- documentation will be found in HTML-format in the directory
  $RUBY_DIR/gems/$RUBY_VERSION/doc/long-decimal-$LONG_DECIMAL_VERSION/rdoc/index.html
  where $RUBY_DIR is the directory containing your ruby-installation,
                  usually /usr/lib/ruby or /usr/local/lib/ruby on
                  Linux/Unix-systems.
        $RUBY_VERSION is the major version of your Ruby, like 1.8
        $LONG_DECIMAL_VERSION is the version of long-decimal that you
                              have installed, like 0.00.20
  on my machine that would be
  /usr/local/lib/ruby/gems/1.8/doc/long-decimal-0.02.01/rdoc/index.html

2. Installing from the sources (it is preferred to use the
   gem-installation, but since long-decimal is open-source-software you
   are off course granted the right to download the source and change
   it and install your own version.)

- download the newest source-tar.gz-file from long-decimal project at rubyforge
  which can be found by
  http://rubyforge.org/projects/long-decimal/ -> Files
  ( http://rubyforge.org/frs/?group_id=1334 )
- open a shell window
  cd to the directory where you have downloaded the .tar.gz-file
  unpack the file using tar
  tar xfzvv long-decimal-beta-1_00.tar.gz
  cd long-decimal
- now you can use rake for several operations
  - rake test
      runs runit tests.  All tests should succeed.
  - rake doc
      creates the documentation
  - rake gem creates the gem-file in a sub-directory pkg
      recommended for installation, proceed as in 1
  - cd pkg
  - gem install --local long-decimal


3. The documentation can be created from the sources.  It is contained
in the gem-file.  It is not provided as a separate file any more.

Bugs
----

It is considered somewhat arbitrary to disallow calculation
exponential functions if the result could not be expressed as Float.
This limitation should be removed, even though it has to be added,
that results of exponentiation that go beyond Float can only be
handled with quite significant calculation effort, because they really
need more than 300 digits.

Certain calculations are too slow.  Algorithms need to be optimized
for speed.  The goal is to keep the algorithms in Ruby-code as long as
possible to make it easier to optimize the algorithm.  If optimization
beyond this level will be needed, C-code might be used, preferably
based on an existing library.  Since long-decimal is intending to
provide full support for JRuby as well, equivalent implementations in
Ruby or Java must be included for libraries written in C.

Even though some mathematical background has already been invested,
more effort from the theoretical side could be useful in order to
choose internal precision parameters in such a way that correctness of
the result to all given digits can be guaranteed with a minimum of
overhead.  Currently parameters are probably slightly too careful,
which slows calculations down.  But it is also possible that they are
insufficient for certain calculations, yielding slightly wrong results
in some very rare situations, "wrong" meaning a deviation of a low
multiple of the unit.

rdoc-documentation and in-code comments are somewhat complete, but for
a sophisticated library like this additional external documentation
should be provided in the long term.  Currently this does not exist at
all.

Please report any bugs you come across.

The status of long-decimal is considered to be production stable.

License
-------

Ruby's license or LGPL
Find copies of these licenses on http://www.gnu.org/ or http://www.ruby-lang.org/
� Karl Brodowsky (IT Sky Consulting GmbH) 2006-2014
http://www.it-sky-consulting.com/

Warranty
--------

This is free software and it comes with absolutely no warranty.
Tests indicate that most functions work
relyably in all situations and all functions work relyably in most
situations.  But do not expect too much!  This is work in progress!  I
do not take any responsibility.  Please use it as it is, change it
according to the terms of the license or wait for a future
version (for which I can't take any warranty either...)

Author
------

Karl Brodowsky
IT Sky Consulting GmbH
http://www.velofahren.de/cgi-bin/mailform.cgi
(no direct mail address because I do not like spam)