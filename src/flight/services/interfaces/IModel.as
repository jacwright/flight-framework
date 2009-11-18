package flight.services.interfaces
{
	public interface IModel
	{
		function isNew():Boolean;
		function serialize():Object;
		function unserialize(value:Object):void;
		function validate():Boolean;
		function toString():String
	}
}