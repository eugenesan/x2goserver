/*
 * This file is part of the  X2Go Project - http://www.x2go.org
 * Copyright (C) 2011-2014 Mike Gabriel <mike.gabriel@das-netzwerkteam.de>
 * Copyright (C) 2011-2014 Moritz 'Morty' Strübe <morty@gmx.net>
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
 * 
 */

int main( int argc, char *argv[] ) {

	char x2gosqlitewrapper[] = TRUSTED_BINARY;

	argv[0] = "x2gosqlitewrapper.pl";
	// execute the script, running with user-rights of this binary
	return execv(x2gosqlitewrapper, argv);

}
