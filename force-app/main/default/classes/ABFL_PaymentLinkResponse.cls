public class ABFL_PaymentLinkResponse {

	public Payment_data payment_data;
	public Order_data order_data;

	public class Payment_data {
		public String pl_order_id;
		//public String merc_order_id;
		public String merc_order_date;
		public String merc_id;
		public String amount;
		public String return_url;
		public String product_type;
		public String product_id;
		public String customer_id;
		public String customer_name;
		public String customer_email;
		public String customer_phone;
		public String invoice_no;
		public String order_desc;
		public String udf1;
		public String udf2;
		public String account_no;
		public String account_ifsc;
		public String allowed_split_payment;
		public String expiry_period;
		public String due_date;
	}

	public class Links {
		public String payment_link_web;
	}

	public class Order_data {
		public String pl_order_id;
		public String created_date;
		public String status;
		public String status_code;
		public Links links;
	}
}