/**************************************************************
 * 
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 * 
 *************************************************************/



#ifndef ACCESSIBILITY_EXT_LISTBOX_ACCESSIBLE
#define ACCESSIBILITY_EXT_LISTBOX_ACCESSIBLE

#include <com/sun/star/uno/RuntimeException.hpp>
#include <tools/link.hxx>

class SvTreeListBox;
class VclSimpleEvent;
class VclWindowEvent;

//........................................................................
namespace accessibility
{
//........................................................................

	//====================================================================
	//= ListBoxAccessibleBase
	//====================================================================
	/** helper class which couples it's life time to the life time of an
		SvTreeListBox
	*/
	class ListBoxAccessibleBase
	{
	private:
		SvTreeListBox* m_pWindow;

	protected:
		inline SvTreeListBox*		getListBox() const
		{
			return	const_cast< ListBoxAccessibleBase* >( this )->m_pWindow;
		}

		inline	bool					isAlive() const		{ return NULL != m_pWindow; }

	public:
		ListBoxAccessibleBase( SvTreeListBox& _rWindow );

	protected:
		virtual ~ListBoxAccessibleBase( );

		// own overridables
		/// will be called for any VclWindowEvent events broadcasted by our VCL window
		virtual void ProcessWindowEvent( const VclWindowEvent& _rVclWindowEvent );

		/** will be called when our window broadcasts the VCLEVENT_OBJECT_DYING event

			<p>Usually, you derive your class from both ListBoxAccessibleBase and XComponent,
			and call XComponent::dispose here.</p>
		*/
		virtual void SAL_CALL dispose() throw ( ::com::sun::star::uno::RuntimeException ) = 0;

		/// to be called in the dispose method of your derived class
		void disposing();

	private:
		DECL_LINK( WindowEventListener, VclSimpleEvent* );

	private:
		ListBoxAccessibleBase( );											// never implemented
		ListBoxAccessibleBase( const ListBoxAccessibleBase& );				// never implemented
		ListBoxAccessibleBase& operator=( const ListBoxAccessibleBase& );	// never implemented
	};

//........................................................................
}	// namespace accessibility
//........................................................................

#endif // ACCESSIBILITY_EXT_LISTBOX_ACCESSIBLE
