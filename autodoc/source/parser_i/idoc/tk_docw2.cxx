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

#include <precomp.h>
#include <s2_dsapi/tk_docw2.hxx>


// NOT FULLY DEFINED SERVICES
#include <s2_dsapi/tokintpr.hxx>



namespace csi
{
namespace dsapi
{

void
Tok_Word::Trigger( TokenInterpreter &	io_rInterpreter ) const
{
	io_rInterpreter.Process_Word(*this);
}

const char *
Tok_Word::Text() const
{
	return sText;
}

void
Tok_Comma::Trigger( TokenInterpreter &	io_rInterpreter ) const
{
	io_rInterpreter.Process_Comma();
}

const char *
Tok_Comma::Text() const
{
	return ",";
}

void
Tok_DocuEnd::Trigger( TokenInterpreter &	io_rInterpreter ) const
{
	io_rInterpreter.Process_DocuEnd();
}

const char *
Tok_DocuEnd::Text() const
{
	return "*/";
}

void
Tok_EOL::Trigger( TokenInterpreter &	io_rInterpreter ) const
{
	io_rInterpreter.Process_EOL();
}

const char *
Tok_EOL::Text() const
{
	return "\r\n";
}

void
Tok_EOF::Trigger( TokenInterpreter & ) const
{
	csv_assert(false);
}

const char *
Tok_EOF::Text() const
{
	return "";
}

void
Tok_White::Trigger( TokenInterpreter &	io_rInterpreter ) const
{
	io_rInterpreter.Process_White();
}

const char *
Tok_White::Text() const
{
	return " ";
}




}   // namespace dsapi
}   // namespace csi

