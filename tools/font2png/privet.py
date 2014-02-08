#! /usr/bin/env python
# -*- coding: utf8 -*-

print ",".join(["'%04x'" % ord (u) for u in u"Привет!"])