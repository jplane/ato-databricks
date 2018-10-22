
import com.bigcorp.math.Calc

import com.databricks.dbutils_v1.DBUtilsV1
import org.apache.spark.sql.SparkSession

dbutils.widgets.text("x", "0", "Upper bound for the Fibonnaci sequence.")

def fib(a: Int = 0, b: Int = 1): Stream[Int] = Stream.cons(a, fib(b, Calc.add(a, b)))

val x = dbutils.widgets.get("x").toInt

fib(1) take x toList
