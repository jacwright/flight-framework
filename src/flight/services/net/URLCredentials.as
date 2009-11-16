package flight.services.net
{
	import com.adobe.crypto.MD5;
	
	import flash.net.URLRequestHeader;
	
	import mx.utils.Base64Encoder;
	
	public class URLCredentials
	{
		public static const AUTH_BASIC:String = 'basic';
		public static const AUTH_DIGEST:String = 'digest';
	
		private var username:String;
		private var password:String;
		private var realm:String;
		private var type:String;
		
		private var header:URLRequestHeader;
	
		public function URLCredentials(username:String, password:String, 
				realm:String = '', type:String = 'basic')
		{
			this.username = username;
			this.password = password;
			this.realm = realm;
			this.type = type;
		}
		
		public function getUrlRequestHeader():URLRequestHeader
		{
			if(header)
				return header;
				
			var auth:String, encoder:Base64Encoder = new Base64Encoder();
			
			if(type == URLCredentials.AUTH_DIGEST) {
				
				auth = username + ":" + realm + ":" + MD5.hash(password);
	        	encoder.encode(auth);
	
				header = new URLRequestHeader("Authorization", 'Digest ' + encoder.toString());
					
			} else {
				
				auth = username + ":" + password;
	        	encoder.encode(auth);
	
				header = new URLRequestHeader("Authorization", 'Basic ' + encoder.toString());					
			}
			
			return header;
		}
	}
}