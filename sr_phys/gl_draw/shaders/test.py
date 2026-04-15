#!/bin/env python3

# Double checking my bisection code... I have b-a opps.

ITERS = 11

def WL(s):
    return (s-0.6)/2

b = 1.0
a = 0

for i in range(ITERS):
    m = (a+b)/2
    print(a,m,b)
    f = WL(m)
    a = m if f<0 else a
    b = m if f>0 else b

print(a,b,WL(a), WL(b))