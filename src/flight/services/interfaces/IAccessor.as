/**
 * Accessor Pattern :: Used to seperate data access complexity from application 
 * logic. Typically used in applications with a db backend. Changes in data 
 * representation will not affect application logic as long as application uses 
 * a generic set of access operations to retrieve data (etc: read, write, delete).
 */
package flight.services.interfaces
{
	import flight.net.IResponse;
	
	public interface IAccessor
	{
		function get mapper():IMapper;
		function set mapper(value:IMapper):void;
		
		function execPost(resourceType:Object, data:Object=null, params:Object=null):IResponse
		function execGet(resourceType:Object, params:Object=null):IResponse
		function execPut(resourceType:Object, data:Object, params:Object=null):IResponse
		function execDelete(resourceType:Object, params:Object=null):IResponse
				
		function execSave(resourceType:Object, data:IModel, params:Object=null):IResponse
	}
}