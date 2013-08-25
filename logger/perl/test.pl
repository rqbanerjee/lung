#!/usr/bin/perl

use Logger;

$logger = new Logger();

Logger->log_debug("this is a debug");

Logger->log_info("this is an info");

Logger->log_warn("this is a warn");

Logger->log_error("this is an error");

Logger->log_fatal("this is FATAL");