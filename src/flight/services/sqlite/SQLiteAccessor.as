package flight.services.sqlite
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.utils.describeType;
	
	import flight.net.IResponse;
	import flight.net.Response;
	import flight.vo.ValueObject;
	
	import flx.service.interfaces.IAccessor;
	import flx.service.interfaces.IMapper;
	import flx.service.interfaces.IModel;

	public class SQLiteAccessor implements IAccessor
	{
		private var conn:SQLConnection = new SQLConnection();
		
		private var _mapper:IMapper;
		
		public function SQLiteAccessor()
		{
		}

		public function get mapper():IMapper
		{
			return _mapper;
		}
		
		public function set mapper(value:IMapper):void
		{
			_mapper = value;
		}
		
		public function execPost(resourceType:Object, data:Object=null, params:Object=null):IResponse
		{
			var table:String = mapper.map(resourceType, params);
			
			var sql:SQLStatement = new SQLStatement();
				sql.sqlConnection = mapper['conn'];

				var keys:Array = [], values:Array = [];
				if(data is ValueObject || data is IModel) {
					var description:XML = describeType(data);
						
				} else {
					for(var e:String in data) {
						keys.push( e );
						var value:Object = data[e];
						if(value is String) {
							value = "\'" + escapeQuotes(value as String) + "\'";						
						}
						values.push( value );
					}
				}
				
				var cols:String = keys.join(',');
				var vals:String = values.join(',');
				
				sql.text = 'INSERT INTO ' + table + ' (' + cols + ') VALUES (' + vals + ')';
				sql.execute();
				
			var response:Response = new Response();
				response.addCompleteEvent(sql, SQLEvent.RESULT);
				response.addCancelEvent(sql, SQLErrorEvent.ERROR);			
				response.addFaultHandler(onFault);

			return response;
		}
		
		public function execUpdate(resourceType:Object, data:Object, params:Object=null):IResponse
		{
			var table:String = mapper.map(resourceType, params);
			
			var sql:SQLStatement = new SQLStatement();
				sql.sqlConnection = mapper['conn'];

				var sets:Array = [];
				if(data is ValueObject || data is IModel) {
					var description:XML = describeType(data);
						
				} else {
					for(var e:String in data) {
						var key:String = data[e];
						var value:Object = data[e];
						if(value is String) {
							value = "\'" + escapeQuotes(value as String) + "\'";						
						}
						sets.push( key + '=' + value );
					}
				}
				
				// UPDATE table_name
				// SET column1=value, column2=value2,...
				// WHERE some_column=some_value
				
				sql.text = 'UPDATE ' + table + ' SET ' + sets;
				sql.execute();
				
			var response:Response = new Response();
				response.addCompleteEvent(sql, SQLEvent.RESULT);
				response.addCancelEvent(sql, SQLErrorEvent.ERROR);			
				response.addFaultHandler(onFault);

			return response;
		}
		
		public function execDelete(resourceType:Object, params:Object=null):IResponse
		{
			return null;
		}
		
		public function execGet(resourceType:Object, params:Object=null):IResponse
		{
			return null;
		}
		
		public function execSave(resourceType:Object, data:IModel, params:Object=null):IResponse
		{
			return null;
		}
		
		private function escapeQuotes(subject:String):String
		{
			return subject.replace( new RegExp("'","g"),"''");
		}
		
		private function onResult(data:Object):void
		{
			trace('success');	
		}
		
		private function onFault(err:Error):void
		{
			trace('failed');
		}
		
	}
}