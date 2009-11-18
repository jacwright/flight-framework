package flight.services.http
{
	import flight.services.abstracts.AbstractMapper;
	import flight.services.net.URLRequestFormat;
	
	public class HTTPMapper extends AbstractMapper
	{
		public var baseUrl:String 				= ''; 	
		public var format:String				= '';	
		
		public function HTTPMapper(baseUrl:String, format:String=URLRequestFormat.JSON)
		{
			this.baseUrl = baseUrl;
			this.format  = format;
		}
		
		override public function map(resource:Object, params:Object=null):String
		{
			var location:String = getLocation(resource);
			if(!location) {
				throw new Error("Mapper could not find map to resource: " + resource);
			} 
			return resolve(location, params); 
		}
		
		protected function resolve(route:String, data:Object = null):String
		{
			// init the url from the default route
			var url:String = route;
			
			data = sanitizeData(data);
			
			// loop through the url looking for :paramId or :param_id values to replace
			// Note, the extractValue will check for both camelized and underscorized properties
			var idValue:String = null;
			var idPattern:RegExp = /:(\w+)/;
			var matches:Array = url.match(idPattern);
			while (matches !== null && matches.length > 0) {
				idValue = extractValue(data, matches[1]);
				url = url.replace(idPattern, idValue);
				matches = url.match(idPattern);
			} 
						
			// remove any double slashes '//', which may exist from empty or missing id values
			var doubleSlashPattern:RegExp = /([^:]\/)(\/)/g;
			matches = url.match(doubleSlashPattern);
			while (matches !== null && matches.length > 0) {
				url = url.replace(doubleSlashPattern, "$1");
				matches = url.match(doubleSlashPattern);
			}
			
			// removing any trailing slashes
			var trailingSlashPattern:RegExp = /([^:])\/$/;
			url = baseUrl + url.replace(trailingSlashPattern, "$1");

			return url;
		}
		
		protected function sanitizeData(data:Object):Object
		{
			// clear out 0 data items
			for (var id:String in data) {
				if (data[id] == 0) {
					data[id] = null; 
				}
			}
			return data;
		}
		
		protected function extractValue(data:Object, param:String):String
		{
			if (data === null || param.length === 0) { return ""; }
			
			var value:String = data.hasOwnProperty(param)? data[param]: null;
			if (value === null) {
				value = "";
			} 
			return value;
		}

	}
}