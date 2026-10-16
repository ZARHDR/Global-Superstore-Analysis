
import pandas as pd
from pathlib import Path

# مسیر فایل اصلی
data_folder = Path("data")
input_file = data_folder / "superstore.csv"
output_file = data_folder / "superstore_sql.csv"

# خواندن فایل اصلی
df = pd.read_csv(input_file, encoding="utf-8-sig")

# حذف ستون اضافی، اگر وجود داشته باشد
df = df.drop(columns=["记录数"], errors="ignore")

# یکسان‌سازی نام ستون‌ها با جدول SQL
rename_columns = {
    "Row.ID": "RowID",
    "Order.ID": "OrderID",
    "Order.Date": "OrderDate",
    "Ship.Date": "ShipDate",
    "Ship.Mode": "ShipMode",
    "Customer.ID": "CustomerID",
    "Customer.Name": "CustomerName",
    "Sub.Category": "SubCategory",
    "Product.ID": "ProductID",
    "Product.Name": "ProductName",
    "Shipping.Cost": "ShippingCost",
    "Order.Priority": "OrderPriority",
    "weeknum": "WeekNum"
}

df = df.rename(columns=rename_columns)

# ذخیره نسخه مخصوص SQL
df.to_csv(output_file, index=False, encoding="utf-8-sig")

print("File created successfully!")
print("Rows:", len(df))
print("Columns:", len(df.columns))
print(df.columns.tolist())