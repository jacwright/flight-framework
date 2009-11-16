package flight.services.abstracts
{
	import flash.net.getClassByAlias;
	import flash.utils.Dictionary;
	
	import flight.errors.AbstractMethodCallError;
	import flight.utils.getType;
	
	import flx.service.interfaces.IMapper;
	
	public class AbstractMapper implements IMapper
	{ 	
		public static function getMapper(className:String, singleInstance:Boolean = true):IMapper
		{
			var MapperClass:Class = getClassByAlias(className);
			return new MapperClass() as IMapper;
		}
			
		private var resourceIndex:Dictionary = new Dictionary();		
		
		public function addResource(resource:Object, location:String):void
		{
			if ( !(resource is String) && !(resource is Class) ) {
				resource = getType(resource);
			}
			
			resourceIndex[resource] = location;
		}
		
		public function map(resource:Object, params:Object=null):String
		{
			AbstractMethodCallError.abstractMethodCall(this, arguments.callee, 'map');
			return null;
		}
		
		protected function getLocation(resource:Object):String
		{
			return resourceIndex[resource];	
		}
		
	}
}