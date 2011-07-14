/*
 * Copyright (C) 2007-2011 X2go Project - http://wiki.x2go.org
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the
 * Free Software Foundation, Inc.,
 * 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * Copyright (C) 2007-2011  Oleksandr Shneyder <oleksandr.shneyder@obviously-nice.de>
 * Copyright (C) 2007-2011  Heinz-Markus Graesing <heinz-m.graesing@obviously-nice.de>
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <libgen.h>

int main() {
	char buffer[BUFSIZ];
	char * x2gosqlitewrapper = NULL;

	// resolve link of /proc/self/exe
	readlink("/proc/self/exe", buffer, BUFSIZ);

	// derive the full path of x2gosqlitewrapper.pl from path of this binary
	asprintf(&x2gosqlitewrapper, "%s/%s", dirname(dirname(buffer)), "lib/x2go/x2gosqlitewrapper.pl");

	// execute the script, taking setuid bit into consideration if set...
	execl(x2gosqlitewrapper, "");

	// fake a successful return value
	return 0;
}
