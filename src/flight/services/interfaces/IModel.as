package flight.services.interfaces
{
	public interface IModel
	{
		function get isNew():Boolean;
		function set isNew(value:Boolean):void;
		
		function serialize():Object;
		function unserialize(value:Object):void;
		function validate():Boolean;
		function toString():String
	}
}