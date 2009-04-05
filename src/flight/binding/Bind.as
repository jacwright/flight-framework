////////////////////////////////////////////////////////////////////////////////
//
//	Copyright (c) 2009 Tyler Wright, Robert Taylor, Jacob Wright
//	
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//	
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//	
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.
//
////////////////////////////////////////////////////////////////////////////////

package flight.binding
{
	import flight.events.PropertyEvent;
	import flight.vo.ValueObject;
	
	import mx.core.IMXMLObject;
	
	/**
	 * The Bind class stands as the primary API for data binding, whether through Bind instances
	 * that represent a target property bound to some data source, or through it's static methods
	 * that allow global binding access. Bind's can be instantiated via ActionScript or MXML and
	 * simplify management of a single binding, allowing target and source to be changed anytime.
	 */
	public class Bind extends ValueObject implements IMXMLObject
	{
		private var _isBound:Boolean = false;
		private var _disabled:Boolean = false;
		private var _twoWay:Boolean = false;
		private var _source:Object;
		private var _sourcePath:String;
		private var _target:Object;
		private var _targetPath:String;
		
		public function Bind(target:Object = null, targetPath:String = null,
							 source:Object = null, sourcePath:String = null, twoWay:Boolean = false):void
		{
			_target = target;
			_targetPath = targetPath;
			_source = source;
			_sourcePath = sourcePath;
			_twoWay = twoWay;
			updateBind([]);
		}
		
		/**
		 * The isBound flag represents whether a target and source have been fully defined (are
		 * not null), and whether the Bind is not disabled. isBound does <em>not</em> reflect the
		 * current state of the binding's resolution, whether or not its paths can be resolved.
		 */
		[Transient]
		[Bindable(event="propertyChange", flight="true")]
		public function get isBound():Boolean
		{
			return _isBound;
		}
		
		/**
		 * Allows the binding to be disabled temporarily. By disabling a binding it will no longer
		 * update the target or source end points, though their values at the time of disabling will
		 * remain unchanged.
		 */
		[Bindable(event="propertyChange", flight="true")]
		public function get disabled():Boolean
		{
			return _disabled;
		}
		public function set disabled(value:Boolean):void
		{
			if (_disabled != value) {
				var oldValues:Array = [_target, _targetPath, _source, _sourcePath];
				var oldValue:Object = _disabled;
				_disabled = value;
				updateBind(oldValues);
				PropertyEvent.dispatchChange(this, "disabled", oldValue, _disabled);
			}
		}
		
		/**
		 * Two-way bindings are useful for easily syncing data between two end points. When two-way
		 * binding is enabled, changes to either the source <em>or</em> the target updates the other.
		 */
		[Bindable(event="propertyChange", flight="true")]
		public function get twoWay():Boolean
		{
			return _twoWay;
		}
		public function set twoWay(value:Boolean):void
		{
			if (_twoWay != value) {
				var oldValues:Array = [_target, _targetPath, _source, _sourcePath];
				var oldValue:Object = _twoWay;
				_twoWay = value;
				updateBind(oldValues);
				PropertyEvent.dispatchChange(this, "twoWay", oldValue, _twoWay);
			}
		}
		
		/**
		 * The target end point receives value updates from the data source every time the source
		 * changes. The target object is the first object in a resolution chain defined by targetPath.
		 */
		[Bindable(event="propertyChange", flight="true")]
		public function get target():Object
		{
			return _target;
		}
		public function set target(value:Object):void
		{
			if (_target != value) {
				var oldValues:Array = [_target, _targetPath, _source, _sourcePath];
				var oldValue:Object = _target;
				_target = value;
				updateBind(oldValues);
				PropertyEvent.dispatchChange(this, "target", oldValue, _target);
			}
		}
		
		/**
		 * The targetPath is a property or property chain to be resolved starting with the target.
		 * The path is a string of one or more dot-separated property names, with the first name
		 * representing a property defined on the target. For example:
		 * <code>targetPath = "button.label.text";</code>
		 */
		[Bindable(event="propertyChange", flight="true")]
		public function get targetPath():String
		{
			return _targetPath;
		}
		public function set targetPath(value:String):void
		{
			if (_targetPath != value) {
				var oldValues:Array = [_target, _targetPath, _source, _sourcePath];
				var oldValue:Object = _targetPath;
				_targetPath = value;
				updateBind(oldValues);
				PropertyEvent.dispatchChange(this, "targetPath", oldValue, _targetPath);
			}
		}
		
		/**
		 * The source end point updates values on the target every time the source changes.
		 * The source object is the first object in a resolution chain defined by sourcePath.
		 */
		[Bindable(event="propertyChange", flight="true")]
		public function get source():Object
		{
			return _source;
		}
		public function set source(value:Object):void
		{
			if (_source != value) {
				var oldValues:Array = [_target, _targetPath, _source, _sourcePath];
				var oldValue:Object = _source;
				_source = value;
				updateBind(oldValues);
				PropertyEvent.dispatchChange(this, "source", oldValue, _source);
			}
		}
		
		/**
		 * The sourcePath is a property or property chain to be resolved starting with the source.
		 * The path is a string of one or more dot-separated property names, with the first name
		 * representing a property defined on the source. For example:
		 * <code>sourcePath = "document.user.name";</code>
		 */
		[Bindable(event="propertyChange", flight="true")]
		public function get sourcePath():String
		{
			return _sourcePath;
		}
		public function set sourcePath(value:String):void
		{
			if (_sourcePath != value) {
				var oldValues:Array = [_target, _targetPath, _source, _sourcePath];
				var oldValue:Object = _sourcePath;
				_sourcePath = value;
				updateBind(oldValues);
				PropertyEvent.dispatchChange(this, "sourcePath", oldValue, _sourcePath);
			}
		}
		
		/**
		 * Allows Bind to automatically set target and source to the host MXML component. This
		 * method is reserved for internal use by MXML instantiated components.
		 * 
		 * @param	document		The MXML component where the Bind is defined.
		 * @param	id				The id of the Bind isn't used internally.
		 */
		public function initialized(document:Object, id:String):void
		{
			if (target == null) {
				target = document;
			}
			if (source == null) {
				source = document;
			}
		}
		
		/**
		 * Removes and adds binding appropriately, depending on changes to target and source, or
		 * to twoWay and disabled. Updates the isBound property accordingly.
		 * 
		 * @param	oldValues		An array of the target, targetPath, source, and sourcePath
		 * 							values prior to the most recent change that triggered the update.
		 */
		private function updateBind(oldValues:Array):void
		{
			var oldValue:Object = _isBound;
			if (_isBound) {
				removeBinding(oldValues[0], oldValues[1], oldValues[2], oldValues[3]);
				_isBound = false;
			}
			
			if (!_disabled && _target != null && _targetPath != null &&
							 _source != null && _sourcePath != null) {
				_isBound = addBinding(_target, _targetPath, _source, _sourcePath, _twoWay);
			}
			
			if (oldValue != _isBound) {
				PropertyEvent.dispatchChange(this, "isBound", oldValue, _isBound);
			}
		}
		
		/**
		 * Global utility method binding a target end point to a data source. Once a target is bound
		 * to the source, their values will synchronize immediately and on each subsequent change on
		 * the source. When enabling a two-way bind the source will also update to match the target.
		 * 
		 * @param	target			A reference to the initial object in the target end point, the
		 * 							recipient of binding updates.
		 * @param	targetPath		A property or dot-separated property chain to be resolved in the
		 * 							target end point.
		 * @param	source			A reference to the initial object in the source end point, the
		 * 							initiator of binding updates.
		 * @param	sourcePath		A property or dot-separated property chain to be resolved in the
		 * 							source end point.
		 * @param	twoWay			When enabled, two-way binding updates both target <em>and</em>
		 * 							source upon changes to either.
		 * 
		 * @return					Considered successful if the binding has not already been established.
		 */
		public static function addBinding(target:Object, targetPath:String, source:Object, sourcePath:String, twoWay:Boolean = false):Boolean
		{
			var binding:Binding = Binding.getBinding(source, sourcePath);
			
			var success:Boolean;
			if (twoWay || targetPath.split(".").length > 1) {
				var binding2:Binding = Binding.getBinding(target, targetPath);
				
				success = binding.bind(binding2, "value");
				if (twoWay) {
					binding2.bind(binding, "value");
				} else {
					binding2.applyOnly = true;
				}
			} else {
				success = binding.bind(target, targetPath);
			}
			return success;
		}
		
		/**
		 * Global utility method destroying bindings made via <code>addBinding</code>. Once the binding
		 * is no longer in effect the properties will not be synchronized. However, source and target
		 * values will not be changed by removing the binding, so they will still match initially.
		 * 
		 * @param	target			A reference to the initial object in the target end point, the
		 * 							recipient of binding updates.
		 * @param	targetPath		A property or dot-separated property chain to be resolved in the
		 * 							target end point.
		 * @param	source			A reference to the initial object in the source end point, the
		 * 							initiator of binding updates.
		 * @param	sourcePath		A property or dot-separated property chain to be resolved in the
		 * 							source end point.
		 * 
		 * @return					Considered successful if the specified binding was available.
		 */
		public static function removeBinding(target:Object, targetPath:String, source:Object, sourcePath:String):Boolean
		{
			var binding:Binding = Binding.getBinding(source, sourcePath);
			var success:Boolean = binding.unbind(target, targetPath);
			
			if (!success) {
				var binding2:Binding = Binding.getBinding(target, targetPath);
				
				success = binding.unbind(binding2, "value");
				binding2.unbind(binding, "value");
				if ( !binding2.hasBinds() ) {
					Binding.releaseBinding(binding2);
				}
			}
			
			if ( !binding.hasBinds() ) {
				Binding.releaseBinding(binding);
			}
			return success;
		}
		
		/**
		 * Global utility method binding an event listener to a data source. Once a listener is bound
		 * to the source, it will receive notification when source values change.
		 * 
		 * @param	listener			An event listener object to be registered with the source binding.
		 * @param	source				A reference to the initial object in the source end point, the
		 * 								initiator of binding updates.
		 * @param	sourcePath			A property or dot-separated property chain to be resolved in the
		 * 								source end point.
		 * @param	useWeakReference	Determines whether the reference to the listener is strong or weak.
		 * 								A weak reference (the default) allows your listener to be garbage-
		 * 								collected. A strong reference does not.
		 */
		public static function addListener(listener:Function, source:Object, sourcePath:String, useWeakReference:Boolean = true):Boolean
		{
			var binding:Binding = Binding.getBinding(source, sourcePath);
			return binding.bindListener(listener, useWeakReference);
		}
		
		/**
		 * Global utility method removing an event listener from a source binding. Once the binding
		 * is no longer in effect the listener will not receive notification when source values change.
		 * 
		 * @param	listener			An event listener object to be removed from the source binding.
		 * @param	source				A reference to the initial object in the source end point, the
		 * 								initiator of binding updates.
		 * @param	sourcePath			A property or dot-separated property chain to be resolved in the
		 * 								source end point.
		 */
		public static function removeListener(listener:Function, source:Object, sourcePath:String):Boolean
		{
			var binding:Binding = Binding.getBinding(source, sourcePath);
			var success:Boolean = binding.unbindListener(listener);
			if ( !binding.hasBinds() ) {
				Binding.releaseBinding(binding);
			}
			return success;
		}
		
	}
}
