#!/usr/bin/perl

use Logger;

Logger->log_debug("test_entity1", "this is a debug");

Logger->log_info("test_entity2", "this is an info");

Logger->log_warn("test_entity1", "this is a warn");

Logger->log_error("test_entity2", "this is an error");

Logger->log_fatal("test_entity3", "this is FATAL");

Logger->log_return_code("my_calling_function", 255);

Logger->log_info("no_entity", "no entity")