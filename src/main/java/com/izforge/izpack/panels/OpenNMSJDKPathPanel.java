/*
 * IzPack - Copyright 2001-2007 Julien Ponge, All Rights Reserved.
 * 
 * http://izpack.org/
 * http://developer.berlios.de/projects/izpack/
 * 
 * Copyright 2007 Benjamin Reed <ranger@opennms.org>
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.izforge.izpack.panels;

import java.io.File;

import com.izforge.izpack.installer.InstallData;
import com.izforge.izpack.installer.InstallerFrame;
import com.izforge.izpack.util.OsVersion;

/**
 * Panel which asks for the JDK path.
 * 
 * @author <a href="mailto:ranger@opennms.org">Benjamin Reed</a>
 * 
 */
public class OpenNMSJDKPathPanel extends JDKPathPanel
{

	private static final long serialVersionUID = 2409651564444892039L;

	public OpenNMSJDKPathPanel(InstallerFrame parent, InstallData idata)
    {
        super(parent, idata);
    }

    public void panelActivate()
    {
        // Resolve the default for chosenPath
        super.panelActivate();

        if (OsVersion.IS_OSX) {
        	idata.setVariable(getVariableName(), "/Library/Java/Home");
        	super.panelActivate();
        }
        
        idata.setVariable("JavaBinaryPath", idata.getVariable(getVariableName()) + File.separator + "bin" + File.separator + "java");
    }

}
