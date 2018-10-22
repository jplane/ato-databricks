
package com.bigcorp.math

import org.scalatest.FunSuite

class CalcTest extends FunSuite {
  test("adding zero and zero yields zero") {
    assert(Calc.add(0, 0) == 0)
  }

  test("adding positive integers yields a positive integer") {
    assert(Calc.add(1, 1) == 2)
  }

  test("adding negative integers yields a negative integer") {
    assert(Calc.add(-1, -1) == -2)
  }

  test("subtracting zero and zero yields zero") {
    assert(Calc.subtract(0, 0) == 0)
  }
}
