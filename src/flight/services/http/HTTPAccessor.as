package flight.services.http
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import flight.errors.ResponseError;
	import flight.log.MessageLog;
	import flight.net.IResponse;
	import flight.net.Response;
	import flight.utils.ObjectEditor;
	
	import flx.service.interfaces.IAccessor;
	import flx.service.interfaces.IMapper;
	import flx.service.interfaces.IModel;
	import flx.service.net.AMFMessage;
	import flx.service.net.URLCredentials;
	import flx.service.net.URLRequestFormat;
	import flx.service.net.URLRequestMethod;

	public class HTTPAccessor implements IAccessor
	{
		private static var accessors:Object = new Object();
		
		public var enableCaching:Boolean = true;
		public var findInCacheFunction:Function;
		public var storeInCacheFunction:Function;
		public var urlVariables:URLVariables;
		
		private var cache:Dictionary = new Dictionary(true);
		private var _mapper:IMapper;
		
		public function HTTPAccessor(mapper:IMapper=null)
		{
			_mapper = mapper;
			
			findInCacheFunction = findInCache;
			storeInCacheFunction = storeInCache;
		}
		
		/**
		 * mapper 
		 * @return 
		 * 
		 */		
		public function get mapper():IMapper
		{
			return _mapper; 
		}
		
		public function set mapper(value:IMapper):void
		{
			_mapper = value;
		}
		
		/**
		 * 
		 * @param resource
		 * @param data
		 * @param params
		 * @return 
		 * 
		 */		
		public function execSave(resourceType:Object, data:IModel, params:Object=null):IResponse
		{
			if(IModel(data).isNew) {
				return execPost(resourceType, data, params);
			} 
			return execUpdate(resourceType, data, params);
		}

		/**
		 * 
		 * @param data
		 * @param params
		 * @return 
		 * 
		 */		
		public function execPost(resourceType:Object, data:Object=null, params:Object=null):IResponse
		{
			var route:String = mapper.map(resourceType, params);
			
			setUrlVariables(params);
			
			var serializedData:Object = (data is IModel) ? IModel(data).serialize() : data;
			
			var response:IResponse = load(route, URLRequestMethod.POST, serializedData);
				response.addFaultHandler(onFault);
			
			return response;
		}
		
		/**
		 * 
		 * @param data
		 * @param conditions
		 * @return 
		 * 
		 */		
		public function execUpdate(resourceType:Object, data:Object, params:Object=null):IResponse
		{
			var route:String = mapper.map(resourceType, params);
			
			var response:IResponse = load(route, URLRequestMethod.PUT, data);
				response.addFaultHandler(onFault);
			
			return response;
		}
		
		/**
		 * 
		 * @param conditions
		 * @return 
		 * 
		 */		
		public function execDelete(resourceType:Object, params:Object=null):IResponse
		{
			var route:String = mapper.map(resourceType, params);
			
			var response:IResponse = load(route, URLRequestMethod.DELETE);
				response.addFaultHandler(onFault);
			
			return response;
		}
		
		/**
		 * 
		 * @param conditions
		 * @return 
		 * 
		 */		
		public function execGet(resourceType:Object, params:Object=null):IResponse
		{
			var route:String = mapper.map(resourceType, params);

			setUrlVariables(params);
			
			var response:IResponse = load(route);
				response.addResultHandler(onGet);
				response.addFaultHandler(onFault);
			
			return response;
		}
		
		private function onGet(result:Object):void
		{
			var list:Array = result.data;
			for(var e:String in list) {
				var lookupItem:Object = findInCacheFunction(cache, list[e]);
				if(lookupItem != null) {
					ObjectEditor.merge(list[e], lookupItem);
					list[e] = lookupItem;
				} else {
					storeInCache(cache, list[e]);
				}
			}
		}
		
		/**
		 * Default findInCacheFunction - searches by 'id' as primary key 
		 * @param cache
		 * @param item
		 * @return 
		 * 
		 */		
		private function findInCache(cache:Dictionary, item:Object):Object
		{
			if('id' in item) {
				if(cache[item.id]) {
					return cache[item.id];
				}
			}
			
			return null;
		}
		
		/**
		 * Default storeInCache - stores by 'id' as primary key 
		 * @param cache
		 * @param item
		 * 
		 */		
		private function storeInCache(cache:Dictionary, item:Object):void
		{
			if(enableCaching && 'id' in item) {
				cache[item.id] = item;
			}
		}
		
		/**
		 * 
		 * @param conditions
		 * @return 
		 * 
		 */		
//		public function fetchOne(resourceType:Object, params:Object=null):IResponse
//		{
//			var route:String = mapper.map(resourceType, params);
//			
//			setUrlVariables(params);
//			
//			var response:IResponse = load(route, URLRequestMethod.GET);
//				response.addResultHandler(onFetchOne);
//				response.addFaultHandler(onFault);
//			
//			return response;
//		}
//		
//		private function onFetchOne(result:Object):void
//		{
//			var list:Array = result.data;
//			if(list.length) {
//				result.data = list[0];
//				if(enableCaching) {
//					var lookupItem:Object = findInCacheFunction(cache, result.data);
//					if(	lookupItem != null ) {
//						ObjectEditor.merge(result.data, lookupItem);
//					} else {
//						storeInCacheFunction(cache, result.data);
//					}
//				}
//			} else {
//				result.data = null;
//			}
//		}
		
		/**
		 * 
		 * 
		 */		
		public function clearCache():void
		{
			cache = new Dictionary(true);
		}
		
		/**
		 * 
		 * @param url
		 * @param method
		 * @param data
		 * @param credentials
		 * @return 
		 * 
		 */		
		public function load(url:String, method:String = URLRequestMethod.GET,
							 data:Object = null, credentials:URLCredentials = null):IResponse
		{
			var urlRequest:URLRequest = new URLRequest(url);
				urlRequest.url = url;
							
			// set the response format (format of data returned)
			urlVariables.format = URLRequestFormat.AMF;
			
			if(method == URLRequestMethod.PUT || method == URLRequestMethod.DELETE) {
				urlVariables.method = method;
				urlRequest.method = URLRequestMethod.POST;
			} else {
				urlRequest.method = method;
			}
			
			if(data != null && urlRequest.method == URLRequestMethod.POST) {
				var amf:ByteArray = new ByteArray();
				var amfMessage:AMFMessage = new AMFMessage();
					amfMessage.addBody(null, null, data);
					amfMessage.writeMessage(amf);
				
				// assign the AMF message contents and set the mime-type 
				urlRequest.data = amf;
				urlRequest.contentType = 'application/x-amf';
							
				if (urlRequest.url.indexOf("?") > 0) {
					// allow existing url params to get through
					urlRequest.url += "&" + urlVariables.toString();
				} else {
					urlRequest.url += "?" + urlVariables.toString();
				}
			} else {
				if(data != null) {
					urlVariables.data = data;
				}
				urlRequest.data = urlVariables;
			}
			
			
			if(credentials != null) {
				urlRequest.requestHeaders.push(credentials.getUrlRequestHeader());
				credentials = null;
			}
			
			var urlLoader:URLLoader = new URLLoader();
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
			urlLoader.load(urlRequest);
			
			var response:Response = new Response();
				response.addCompleteEvent(urlLoader, Event.COMPLETE);
				response.addProgressEvent(urlLoader, ProgressEvent.PROGRESS);
				response.addCancelEvent(urlLoader, SecurityErrorEvent.SECURITY_ERROR);
				response.addCancelEvent(urlLoader, IOErrorEvent.IO_ERROR);
			
			response.addResultHandler(onResult);
			
			return response;
		}
		
		private function setUrlVariables(params:Object=null):void
		{
			urlVariables = new URLVariables();

			if(params == null) {
				return;
			}			
			
			for(var e:String in params) {
				urlVariables[e] = params[e]
			}
		}
		
		private function onResult(data:Object):Object
		{
			var byteArray:ByteArray = data.data as ByteArray;
			
			try {
				var amfMessage:AMFMessage = new AMFMessage();
				amfMessage.readMessage(byteArray);
				data = amfMessage.firstDataObject;
				byteArray.position = 0;
				
				if(data.error != null) {
					throw new ResponseError(data.error.message);
				}
				
			} catch(error:ResponseError) {
				throw error;
			} catch(error:Error) {
				throw new ResponseError("Invalid AMF response: " + byteArray.toString());
			}
			
			return data;
		}
		
		/**
		 * 
		 * @param err
		 * 
		 */		
		private function onFault(err:Error):void
		{
			MessageLog.getMessageLog().error(err.message, err);
		}
		
	}
}