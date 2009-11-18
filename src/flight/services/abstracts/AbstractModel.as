package flight.services.abstracts
{
	import flight.services.interfaces.IModel;
	import flight.utils.ObjectEditor;
	import flight.utils.getClassName;
	import flight.vo.ValueObject;

	public class AbstractModel extends ValueObject implements IModel
	{
		public function AbstractModel()
		{
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function isNew():Boolean
		{
			if('id' in this) {
				return this['id'] < 1;
			}
			
			return false;
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function serialize():Object
		{
			return this;
		}
		
		/**
		 * 
		 * @param value
		 * 
		 */		
		public function unserialize(value:Object):void
		{
			ObjectEditor.merge(value, this);
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function validate():Boolean
		{
			return true;
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */		
		public function toString():String
		{
			return getClassName(this);
		}
		
	}
}